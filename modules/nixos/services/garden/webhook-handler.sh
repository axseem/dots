#!/usr/bin/env bash
set -euo pipefail

CACHE_PATH="${1:-/var/cache/garden-build}"
SITE_PATH="${2:-/var/www/garden}"
REPO_URL="${3:-https://codeberg.org/axseem/garden}"
BRANCH="${4:-main}"

REPO_DIR="$CACHE_PATH/repo"
CURRENT_LINK="$SITE_PATH/current"

ensure_repo() {
    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "Cloning repository..."
        git clone "$REPO_URL" "$REPO_DIR"
    fi
}

pull_latest() {
    echo "Pulling latest changes..."
    cd "$REPO_DIR"
    git fetch origin
    git reset --hard "origin/$BRANCH"
}

build_site() {
    echo "Building site..."
    cd "$REPO_DIR"
    
    nix build . --out-link "$CACHE_PATH/result-new"
}

deploy_site() {
    echo "Deploying site atomically..."
    
    local timestamp
    timestamp=$(date +%Y%m%d%H%M%S)
    local deploy_dir="$SITE_PATH/releases/$timestamp"
    
    mkdir -p "$SITE_PATH/releases"
    cp -rL "$CACHE_PATH/result-new" "$deploy_dir"
    chmod -R 755 "$deploy_dir"
    
    ln -sfn "$deploy_dir" "$CURRENT_LINK"
    
    echo "Cleaning old releases..."
    find "$SITE_PATH/releases" -mindepth 1 -maxdepth 1 -type d | \
        sort -r | \
        tail -n +6 | \
        while read -r old_release; do
            echo "Removing old release: $old_release"
            rm -rf "$old_release"
        done
    
    rm -f "$CACHE_PATH/result-new"
}

needs_build() {
    cd "$REPO_DIR"
    git fetch origin
    
    local local_commit
    local remote_commit
    local_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
    remote_commit=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "")
    
    if [ -z "$local_commit" ]; then
        echo "No local commit, build needed"
        return 0
    fi
    
    if [ "$local_commit" = "$remote_commit" ]; then
        echo "Already at latest commit, skipping build"
        return 1
    fi
    
    echo "New commits available, build needed"
    return 0
}

main() {
    ensure_repo
    
    if [ "${SKIP_IDEMPOTENCY_CHECK:-}" != "1" ] && ! needs_build; then
        echo "Deployment skipped (already up to date)"
        exit 0
    fi
    
    pull_latest
    build_site
    deploy_site
    echo "Deployment complete!"
}

main "$@"
