#!/usr/bin/env bash
set -euo pipefail

SECRETS_DIR="${SECRETS_DIR:-/var/secrets/nebula}"
NEBULA_BIN="${NEBULA_BIN:-nebula-cert}"
ORG="${ORG:-axseem-mesh}"
CA_VALIDITY="${CA_VALIDITY:-8760h}"
HOST_VALIDITY="${HOST_VALIDITY:-8760h}"

mkdir -p "$SECRETS_DIR"
cd "$SECRETS_DIR"

if [[ ! -f ca.crt || ! -f ca.key ]]; then
    echo "Generating CA certificate..."
    "$NEBULA_BIN" ca -name "$ORG" -duration "$CA_VALIDITY"
    chmod 644 ca.crt
    chmod 600 ca.key
    echo "CA certificate generated: $SECRETS_DIR/ca.crt"
else
    echo "CA certificate already exists, skipping..."
fi

generate_host() {
    local name="$1"
    local ip="$2"
    
    if [[ -f "${name}.crt" && -f "${name}.key" ]]; then
        echo "Host certificate for $name already exists, skipping..."
        return
    fi
    
    echo "Generating certificate for $name with IP $ip..."
    "$NEBULA_BIN" sign -name "$name" -ip "$ip" -ca-crt ca.crt -ca-key ca.key -duration "$HOST_VALIDITY"
    chmod 644 "${name}.crt"
    chmod 600 "${name}.key"
    echo "Host certificate generated: $SECRETS_DIR/${name}.crt"
}

echo ""
echo "Nebula Certificate Generator"
echo "============================="
echo "Secrets directory: $SECRETS_DIR"
echo ""

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <hostname:ip> [hostname:ip] ..."
    echo ""
    echo "Example:"
    echo "  $0 axsmsrvr:10.10.0.1/24 ideapad:10.10.0.2/24 phone:10.10.0.3/24"
    echo ""
    echo "This will generate certificates for each host with the specified mesh IP."
    echo ""
    echo "After generation, copy the appropriate files to each host:"
    echo "  - All hosts need: ca.crt"
    echo "  - Each host needs its own: <hostname>.crt and <hostname>.key"
    echo ""
    echo "On each host, rename or symlink to host.crt and host.key, or configure"
    echo "the NixOS module to use the specific paths."
    exit 1
fi

for host_spec in "$@"; do
    name="${host_spec%%:*}"
    ip="${host_spec#*:}"
    generate_host "$name" "$ip"
done

echo ""
echo "Certificate generation complete!"
echo ""
echo "Files in $SECRETS_DIR:"
ls -la "$SECRETS_DIR"
echo ""
echo "Deployment instructions:"
echo "  1. Copy ca.crt to all hosts"
echo "  2. Copy each host's .crt and .key to that host"
echo "  3. On each host, place files in /var/secrets/nebula/"
echo "     as host.crt, host.key, and ca.crt"
