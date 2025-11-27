pipeline {
    agent any

    environment {
        APP_SERVER = "omkar@192.168.152.129"
        BACKEND_PATH = "/opt/ems-app/backend"
        FRONTEND_PATH = "/opt/ems-app/frontend"
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Deploy Backend') {
            steps {
                sh '''
                    echo "🚀 Deploying backend WITHOUT touching node_modules..."

                    # Sync everything EXCEPT node_modules
                    rsync -avz \
                        --exclude=node_modules \
                        --exclude=.env \
                        backend/ $APP_SERVER:$BACKEND_PATH/

                    echo "📦 Running npm install on server..."
                    ssh -o StrictHostKeyChecking=no $APP_SERVER "
                        cd $BACKEND_PATH &&
                        npm install --legacy-peer-deps &&
                        sudo systemctl restart ems-backend
                    "
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                    echo "🧩 Syncing frontend..."

                    rsync -avz \
                        --exclude=node_modules \
                        frontend/ $APP_SERVER:$FRONTEND_PATH/

                    echo "🌐 Restarting Nginx..."
                    ssh -o StrictHostKeyChecking=no $APP_SERVER "sudo systemctl reload nginx"
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "🔍 Checking application..."
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.152.129)

                    if [ "$STATUS" != "200" ]; then
                        echo "❌ Healthcheck failed! HTTP $STATUS"
                        exit 1
                    else
                        echo "✔ Healthcheck passed!"
                    fi
                '''
            }
        }
    }

    post {
        success { echo "🎉 Deployment SUCCESS!" }
        failure { echo "⚠ Deployment FAILED! Check logs." }
    }
}
