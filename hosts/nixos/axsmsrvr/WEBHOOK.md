# Garden Webhook Setup

## Webhook Configuration

The garden site auto-deploys when changes are pushed to the Codeberg repository.

### Webhook Endpoint
```
URL: http://axsmsrvr:9000/hooks/garden
Method: POST
Content-Type: application/json
```

### Codeberg Setup

1. Go to your repository settings on Codeberg
2. Navigate to "Webhooks"
3. Click "Add Webhook" and select "Forgejo"
4. Configure:
   - **Target URL:** `http://YOUR_VPS_IP:9000/hooks/garden`
   - **HTTP Method:** POST
   - **Content Type:** application/json
   - **Secret:** Generate a secure random string
   - **Trigger On:** Push events

### Secret Configuration

On the VPS, create the secret file:
```bash
echo "your-secure-secret-here" | sudo tee /var/secrets/garden-webhook-secret
sudo chmod 600 /var/secrets/garden-webhook-secret
sudo chown garden:garden /var/secrets/garden-webhook-secret
```

### How It Works

1. Codeberg sends a POST request with an HMAC-SHA256 signature
2. The webhook server verifies the signature
3. If valid, it triggers the build handler
4. The handler pulls latest changes and runs `nix build`
5. Built site is deployed to `/var/www/garden`

### Manual Deployment

To manually trigger a build:
```bash
sudo -u garden /nix/store/xxx-garden-webhook-handler/bin/garden-webhook-handler \
  /var/cache/garden-build \
  /var/www/garden \
  https://codeberg.org/axseem/garden
```

### Troubleshooting

Check logs:
```bash
journalctl -u garden-webhook -f
journalctl -u garden-initial-build -f
```
