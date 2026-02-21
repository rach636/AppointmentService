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
        IMAGE_TAG = "${BUILD_NUMBER}"
        SONAR_HOST_URL = credentials('sonar-host-url')
        SONAR_LOGIN = credentials('sonar-login-token')
        GIT_REPO = 'https://github.com/rach636/AppointmentService.git'
        APP_NAME = 'appointment-service'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    stages {
        stage('Clone') {
            steps {
                script {
                    echo "Cloning repository..."
                    git branch: 'main', 
                        credentialsId: 'github-credentials', 
                        url: "${GIT_REPO}"
                }
            }
        }

        stage('Gitleak') {
            steps {
                script {
                    echo "Running Gitleak for secret scanning..."
                    sh '''
                        docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source /path --verbose
                    '''
                }
            }
        }

        stage('NPM') {
            steps {
                script {
                    echo "Installing dependencies and building..."
                    sh '''
                        node --version
                        npm --version
                        npm ci
                        npm run build
                    '''
                }
            }
        }

        stage('SonarQube') {
            steps {
                script {
                    echo "Running SonarQube analysis..."
                    sh '''
                        npm install -g sonar-scanner
                        sonar-scanner \
                            -Dsonar.projectKey=appointment-service \
                            -Dsonar.sources=src \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_LOGIN} \
                            -Dsonar.projectVersion=${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Docker Login and Push to ECR') {
            steps {
                script {
                    echo "Building Docker image and pushing to ECR..."
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        docker build -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} .
                        docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                        
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    '''
                }
            }
        }

        stage('Trivy') {
            steps {
                script {
                    echo "Running Trivy vulnerability scan on Docker image..."
                    sh '''
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy image --severity HIGH,CRITICAL \
                            --exit-code 1 \
                            ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Cleaning up Docker images..."
                sh 'docker rmi ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} || true'
            }
        }
        success {
            echo "Pipeline executed successfully for ${APP_NAME}"
        }
        failure {
            echo "Pipeline failed for ${APP_NAME}"
        }
    }
}
