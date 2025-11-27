#!/usr/bin/env bash
set -euo pipefail
cd "/opt/ems-app/backend"

echo "📦 Installing production dependencies (npm ci for reproducible install)..."
if [ -f package-lock.json ]; then
  npm ci --omit=dev --no-audit --no-fund
else
  npm install --omit=dev --no-audit --no-fund
fi

echo "🔁 Reloading systemd & restarting service..."
# require passwordless sudo for these commands (see README steps)
sudo systemctl daemon-reload || true
sudo systemctl restart ems-backend

# wait for service to be active and respond on local port
MAX_TRIES=20
SLEEP_SEC=3
i=0
echo "⏱  Waiting for backend to respond on localhost:3001..."
while [ $i -lt $MAX_TRIES ]; do
  if systemctl is-active --quiet ems-backend; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3001/employees || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
      echo "✔ Backend is up (200)."
      exit 0
    else
      echo "…service running but /employees returned $HTTP_CODE — waiting ($((i+1))/$MAX_TRIES)"
    fi
  else
    echo "…systemd says service not active yet — waiting ($((i+1))/$MAX_TRIES)"
  fi
  i=$((i+1))
  sleep $SLEEP_SEC
done

echo "❌ Backend did not become healthy within timeout. Printing last 200 journal lines:"
sudo journalctl -u ems-backend -n 200 --no-pager || true
exit 2
