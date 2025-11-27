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
                    echo "🚀 Deploying backend..."

                    # Sync backend code (delete old files)
                    rsync -avz --delete backend/ $APP_SERVER:$BACKEND_PATH/

                    # Clean and reinstall dependencies on server
                    ssh -o StrictHostKeyChecking=no $APP_SERVER "
                        cd $BACKEND_PATH &&
                        rm -rf node_modules &&
                        npm install &&
                        sudo systemctl restart ems-backend
                    "
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                    echo "🧩 Deploying frontend..."

                    rsync -avz --delete frontend/ $APP_SERVER:$FRONTEND_PATH/
                    ssh -o StrictHostKeyChecking=no $APP_SERVER "sudo systemctl reload nginx"
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "🔍 Performing health check..."
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.152.129)
                    if [ "$STATUS" != "200" ]; then
                        echo "❌ Healthcheck failed! Status: $STATUS"
                        exit 1
                    else
                        echo "✔ Healthcheck passed!"
                    fi
                '''
            }
        }
    }

    post {
        success { echo "🎉 Application Deployment SUCCESS!" }
        failure { echo "⚠ Deployment FAILED — Check Logs" }
    }
}
