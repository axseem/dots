#!/usr/bin/env python3
import argparse
import fcntl
import hashlib
import hmac
import http.server
import json
import os
import socket
import subprocess
import sys


def verify_signature(payload: bytes, signature: str, secret: str) -> bool:
    if not signature.startswith("sha256="):
        return False
    expected_sig = (
        "sha256=" + hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    )
    return hmac.compare_digest(expected_sig, signature)


class TimeoutHTTPServer(http.server.HTTPServer):
    timeout = 30

    def get_request(self):
        conn, addr = super().get_request()
        conn.settimeout(self.timeout)
        return conn, addr


class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def __init__(
        self,
        *args,
        secret_path: str,
        handler_script: str,
        cache_path: str,
        site_path: str,
        repo_url: str,
        branch: str,
        **kwargs,
    ):
        self.secret_path = secret_path
        self.handler_script = handler_script
        self.cache_path = cache_path
        self.site_path = site_path
        self.repo_url = repo_url
        self.branch = branch
        super().__init__(*args, **kwargs)

    def log_message(self, format, *args):
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), format % args))

    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "healthy"}')
        else:
            self.send_error(404, "Not Found")

    def do_POST(self):
        if self.path != "/hooks/garden":
            self.send_error(404, "Not Found")
            return

        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            self.send_error(400, "Empty payload")
            return

        if content_length > 10 * 1024 * 1024:
            self.send_error(413, "Payload too large")
            return

        signature = self.headers.get("X-Hub-Signature-256", "")
        if not signature:
            self.send_error(401, "Missing signature")
            return

        if not signature.startswith("sha256="):
            self.send_error(401, "Invalid signature format")
            return

        try:
            with open(self.secret_path, "r") as f:
                secret = f.read().strip()
        except Exception as e:
            self.log_message("Failed to read secret: %s", e)
            self.send_error(500, "Configuration error")
            return

        if not secret:
            self.log_message("Secret file is empty")
            self.send_error(500, "Configuration error")
            return

        payload = self.rfile.read(content_length)

        if not verify_signature(payload, signature, secret):
            self.send_error(401, "Invalid signature")
            return

        try:
            data = json.loads(payload)
            self.log_message(
                "Received push from %s",
                data.get("repository", {}).get("full_name", "unknown"),
            )
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON payload")
            return

        ref = data.get("ref", "")
        if ref and ref != f"refs/heads/{self.branch}":
            self.log_message("Ignoring push to %s (watching %s)", ref, self.branch)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "ignored", "reason": "branch mismatch"}')
            return

        lock_path = os.path.join(self.cache_path, ".build.lock")
        try:
            with open(lock_path, "w") as lock_file:
                try:
                    fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                except BlockingIOError:
                    self.log_message("Build already in progress, skipping")
                    self.send_response(429)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(
                        b'{"status": "skipped", "reason": "build in progress"}'
                    )
                    return

                self.log_message("Triggering build...")
                try:
                    result = subprocess.run(
                        [
                            self.handler_script,
                            self.cache_path,
                            self.site_path,
                            self.repo_url,
                            self.branch,
                        ],
                        capture_output=True,
                        text=True,
                        timeout=600,
                    )
                    self.log_message("Build output: %s", result.stdout)
                    if result.returncode != 0:
                        self.log_message("Build failed: %s", result.stderr)
                        self.send_response(500)
                        self.send_header("Content-Type", "application/json")
                        self.end_headers()
                        self.wfile.write(
                            b'{"status": "error", "reason": "build failed"}'
                        )
                        return

                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(b'{"status": "success"}')
                except subprocess.TimeoutExpired:
                    self.log_message("Build timed out")
                    self.send_response(504)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(b'{"status": "error", "reason": "build timeout"}')
                except Exception as e:
                    self.log_message("Build error: %s", e)
                    self.send_response(500)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(b'{"status": "error", "reason": "internal error"}')
        except IOError as e:
            self.log_message("Lock file error: %s", e)
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "error", "reason": "lock error"}')


def make_handler(
    secret_path: str,
    handler_script: str,
    cache_path: str,
    site_path: str,
    repo_url: str,
    branch: str,
):
    class Handler(WebhookHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(
                *args,
                secret_path=secret_path,
                handler_script=handler_script,
                cache_path=cache_path,
                site_path=site_path,
                repo_url=repo_url,
                branch=branch,
                **kwargs,
            )

    return Handler


def main():
    parser = argparse.ArgumentParser(description="Garden webhook receiver")
    parser.add_argument("--port", type=int, default=9000, help="Port to listen on")
    parser.add_argument("--secret-path", required=True, help="Path to webhook secret")
    parser.add_argument("--handler", required=True, help="Path to build handler script")
    parser.add_argument("--cache-path", required=True, help="Path for build cache")
    parser.add_argument("--site-path", required=True, help="Path for built site")
    parser.add_argument("--repo-url", required=True, help="Git repository URL")
    parser.add_argument("--branch", default="main", help="Git branch to track")
    args = parser.parse_args()

    handler = make_handler(
        args.secret_path,
        args.handler,
        args.cache_path,
        args.site_path,
        args.repo_url,
        args.branch,
    )

    server = TimeoutHTTPServer(("127.0.0.1", args.port), handler)
    print(f"Listening on 127.0.0.1:{args.port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
