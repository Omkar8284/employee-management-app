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
                    echo "🚀 Syncing backend files (excluding node_modules)..."
                    rsync -avz \
                        --exclude=node_modules \
                        --exclude=.env \
                        backend/ $APP_SERVER:$BACKEND_PATH/

                    echo "⚙ Running backend deploy script on server..."
                    ssh -o StrictHostKeyChecking=no $APP_SERVER "
                        /opt/ems-app/backend/backend-deploy.sh
                    "
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                    echo "📦 Syncing frontend..."
                    rsync -avz --delete frontend/ $APP_SERVER:$FRONTEND_PATH/

                    echo "🔄 Reloading NGINX..."
                    ssh -o StrictHostKeyChecking=no $APP_SERVER "
                        sudo systemctl reload nginx
                    "
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "🔍 Checking backend health..."
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.152.129:3001/employees)

                    if [ "$STATUS" != "200" ]; then
                        echo "❌ Health check failed! Backend not responding."
                        exit 1
                    else
                        echo "✔ Backend is healthy!"
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment SUCCESS!"
        }
        failure {
            echo "⚠ Deployment FAILED! Check logs."
        }
    }
}
