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
                    echo "Deploying backend..."
                    rsync -avz backend/ $APP_SERVER:$BACKEND_PATH/
                    ssh $APP_SERVER "sudo systemctl restart ems-backend"
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                    echo "Deploying frontend..."
                    rsync -avz frontend/ $APP_SERVER:$FRONTEND_PATH/
                    ssh $APP_SERVER "sudo systemctl reload nginx"
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.152.129)
                    if [ "$STATUS" != "200" ]; then
                        echo "Healthcheck failed!"
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        success { echo "Deployment SUCCESS" }
        failure { echo "Deployment FAILED" }
    }
}
