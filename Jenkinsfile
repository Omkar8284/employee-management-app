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

                    # Copy backend files (WITHOUT deleting important folders)
                    rsync -avz backend/ $APP_SERVER:$BACKEND_PATH/

                    echo "📦 Installing backend dependencies on server..."

                    ssh -o StrictHostKeyChecking=no $APP_SERVER "
                        cd $BACKEND_PATH &&
                        rm -rf node_modules &&              # Clean reinstall
                        npm install --production &&        # Install express/mysql2/cors
                        sudo systemctl restart ems-backend # Restart service
                    "
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                    echo "🧩 Deploying frontend..."

                    rsync -avz --delete frontend/ $APP_SERVER:$FRONTEND_PATH/

                    ssh -o StrictHostKeyChecking=no $APP_SERVER "
                        sudo systemctl reload nginx
                    "
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "🔍 Performing health check..."
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.152.129)

                    if [ "$STATUS" != "200" ]; then
                        echo "❌ Healthcheck FAILED — Status: $STATUS"
                        exit 1
                    else
                        echo "✔ Healthcheck PASSED!"
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Application Deployment SUCCESS!"
        }
        failure {
            echo "⚠ Deployment FAILED — Check Logs"
        }
    }
}
