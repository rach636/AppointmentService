pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPOSITORY = 'appointment-service'
        ECR_URI = '035736213603.dkr.ecr.us-east-1.amazonaws.com/appointment-service'
        IMAGE_TAG = "${BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/rach636/AppointmentService.git'
        APP_NAME = 'appointment-service'
    }

options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo "Cloning repository..."
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('Generate package-lock.json') {
            steps {
                echo "Checking package-lock.json..."

                sh '''
                if [ ! -f package-lock.json ]; then
                    echo "Generating lock file..."
                    docker run --rm \
                      -v $(pwd):/app \
                      -w /app \
                      node:20-alpine \
                      npm install --package-lock-only
                else
                    echo "package-lock.json already exists"
                fi
                '''
            }
        }

        stage('Install Dependencies') {
    steps {
        echo "Installing dependencies and patching Node.js vulnerabilities..."

        sh '''
        docker run --rm \
          -v $(pwd):/app \
          -w /app \
          node:20-alpine sh -c "\
            apk update && apk upgrade --no-cache && \
            npm ci --omit=dev && \
            npm audit fix --production \
          "
        '''
    }
}

        stage('Gitleaks Scan') {
            steps {
                echo "Running Gitleaks scan..."

                sh '''
                docker run --rm \
                  -v $(pwd):/repo \
                  zricethezav/gitleaks:latest detect \
                  --source /repo \
                  --exit-code 1 \
                  --verbose
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."

                withSonarQubeEnv('sonarcube-app') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=AppointmentService \
                      -Dsonar.sources=src \
                      -Dsonar.projectVersion=${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."

                sh '''
                docker build -t ${ECR_URI}:${IMAGE_TAG} .
                docker tag ${ECR_URI}:${IMAGE_TAG} ${ECR_URI}:latest
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                echo "Scanning Docker image with Trivy..."

                sh '''
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy:latest image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --no-progress \
                  ${ECR_URI}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                echo "Logging into ECR and pushing image..."

                sh '''
                aws ecr get-login-password --region ${AWS_REGION} \
                | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                docker push ${ECR_URI}:${IMAGE_TAG}
                docker push ${ECR_URI}:latest
                '''
            }
        }

    }

    post {

        always {
            echo "Cleaning up Docker images..."

            sh '''
            docker rmi ${ECR_URI}:${IMAGE_TAG} || true
            docker rmi ${ECR_URI}:latest || true
            '''
        }

        success {
            echo "Pipeline executed successfully for ${APP_NAME}"
        }

        failure {
            echo "Pipeline failed for ${APP_NAME}"
        }
    }
}
