pipeline {
  agent any

  environment {
    APP_SERVER = "omkar@192.168.152.129"
    BACKEND_PATH = "/opt/ems-app/backend"
    FRONTEND_PATH = "/opt/ems-app/frontend"
    HEALTH_URL = "http://192.168.152.129:3001/employees"
    SSH_OPTS = "-o StrictHostKeyChecking=no"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Deploy Backend') {
      steps {
        script {
          // sync code but exclude node_modules and .env (keep server-managed secrets intact)
          sh """
            echo "🚀 Syncing backend files (excluding node_modules/.env)..."
            rsync -avz --delete --exclude=node_modules --exclude=.env backend/ ${APP_SERVER}:${BACKEND_PATH}/
          """

          // run a deploy script on the server which installs deps, restarts systemd and waits for service
          sh """
            echo "⚙ Running backend deploy on remote server..."
            ssh ${SSH_OPTS} ${APP_SERVER} 'bash -s' <<'REMOTE'
              set -euo pipefail
              cd ${BACKEND_PATH}

              # create backend-deploy.sh if missing (idempotent)
              cat > backend-deploy.sh <<'EOH'
#!/usr/bin/env bash
set -euo pipefail
cd "${BACKEND_PATH}"

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
echo "⏱ Waiting for backend to respond on localhost:3001..."
while [ \$i -lt \$MAX_TRIES ]; do
  if systemctl is-active --quiet ems-backend; then
    HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3001/employees || echo "000")
    if [ "\$HTTP_CODE" = "200" ]; then
      echo "✔ Backend is up (200)."
      exit 0
    else
      echo "…service running but /employees returned \$HTTP_CODE — waiting (\$((i+1))/\$MAX_TRIES)"
    fi
  else
    echo "…systemd says service not active yet — waiting (\$((i+1))/\$MAX_TRIES)"
  fi
  i=\$((i+1))
  sleep \$SLEEP_SEC
done

echo "❌ Backend did not become healthy within timeout. Printing last 200 journal lines:"
sudo journalctl -u ems-backend -n 200 --no-pager || true
exit 2
EOH
              chmod +x backend-deploy.sh

              # run it
              ./backend-deploy.sh
REMOTE
          """
        }
      }
    }

    stage('Deploy Frontend') {
      steps {
        sh """
          echo "🧩 Deploying frontend..."
          rsync -avz --delete frontend/ ${APP_SERVER}:${FRONTEND_PATH}/
          ssh ${SSH_OPTS} ${APP_SERVER} "sudo systemctl reload nginx || true"
        """
      }
    }

    stage('Health Check (public)') {
      steps {
        script {
          sh """
            echo "🔍 Final health-check (external) — retrying up to 10 times..."
            MAX=10
            i=0
            while [ \$i -lt \$MAX ]; do
              STATUS=\$(curl -s -o /dev/null -w "%{http_code}" ${HEALTH_URL} || echo "000")
              echo "→ health check attempt \$((i+1)): \$STATUS"
              if [ "\$STATUS" = "200" ]; then
                echo "✔ Public healthcheck OK."
                exit 0
              fi
              i=\$((i+1))
              sleep 3
            done
            echo "❌ Health check failed after \$MAX tries. Failing pipeline."
            exit 1
          """
        }
      }
    }
  }

  post {
    success { echo "🎉 Deployment SUCCESS!" }
    failure {
      echo "⚠ Deployment FAILED — see console output and remote journalctl for details."
    }
  }
}
