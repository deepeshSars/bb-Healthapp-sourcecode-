pipeline {
    agent any

    environment {

        AWS_REGION = "ap-south-1"

        AWS_ACCOUNT_ID = "591234567890"

        ECR_FRONTEND = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bbhealthapp-frontend"
        ECR_MASTER = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bbhealthapp-master-service"
        ECR_REGISTER = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bbhealthapp-register-service"
        ECR_DOCUMENT = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bbhealthapp-document-service"

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check Required Tools') {
            steps {
                sh '''
                    echo "Checking for required tools..."
                    
                    # Check Maven
                    if ! command -v mvn &> /dev/null; then
                        echo "WARNING: Maven not found. Please install Maven on the Jenkins agent."
                        echo "Installation: sudo apt-get install -y maven"
                    else
                        echo "Maven: $(mvn -version | head -n 1)"
                    fi

                    # Check Docker
                    if ! command -v docker &> /dev/null; then
                        echo "WARNING: Docker not found. Please install Docker on the Jenkins agent."
                        echo "Follow instructions at: https://docs.docker.com/engine/install/"
                    else
                        echo "Docker: $(docker --version)"
                    fi

                    # Check AWS CLI
                    if ! command -v aws &> /dev/null; then
                        echo "WARNING: AWS CLI not found. Please install AWS CLI on the Jenkins agent."
                        echo "Installation: curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && unzip awscliv2.zip && sudo ./aws/install"
                    else
                        echo "AWS CLI: $(aws --version)"
                    fi

                    # Check kubectl
                    if ! command -v kubectl &> /dev/null; then
                        echo "WARNING: kubectl not found. Please install kubectl on the Jenkins agent."
                        echo "Installation: curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
                    else
                        echo "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'version check failed')"
                    fi

                    # Check Java
                    if ! command -v java &> /dev/null; then
                        echo "WARNING: Java not found. Please install Java (JDK 11 or higher) on the Jenkins agent."
                    else
                        echo "Java: $(java -version 2>&1 | head -n 1)"
                    fi
                '''
            }
        }

        stage('Verify Tools') {
            steps {
                sh 'java -version'
                sh 'mvn -version'
                sh 'docker --version'
                sh 'aws --version'
                sh 'kubectl version --client'
            }
        }

        stage('Login to AWS ECR') {
            steps {

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {

                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }

            }
        }

        stage('Build Frontend Image') {

            steps {

                dir('bbhealthapp-frontend') {

                    sh """
                    docker build -t ${ECR_FRONTEND}:${IMAGE_TAG} .
                    """

                }

            }

        }

        stage('Build Master Service') {

            steps {

                dir('bbhealthapp-backend/bbhealthapp-api-master') {

                    sh 'mvn clean package -DskipTests'

                    sh """
                    docker build -t ${ECR_MASTER}:${IMAGE_TAG} .
                    """

                }

            }

        }

        stage('Build Register Service') {

            steps {

                dir('bbhealthapp-backend/bbhealthapp-api-register') {

                    sh 'mvn clean package -DskipTests'

                    sh """
                    docker build -t ${ECR_REGISTER}:${IMAGE_TAG} .
                    """

                }

            }

        }

        stage('Build Document Service') {

            steps {

                dir('bbhealthapp-backend/bbhealthapp-api-document') {

                    sh 'mvn clean package -DskipTests'

                    sh """
                    docker build -t ${ECR_DOCUMENT}:${IMAGE_TAG} .
                    """

                }

            }

        }

        stage('Push Images to ECR') {

            steps {

                sh """
                docker push ${ECR_FRONTEND}:${IMAGE_TAG}
                docker push ${ECR_MASTER}:${IMAGE_TAG}
                docker push ${ECR_REGISTER}:${IMAGE_TAG}
                docker push ${ECR_DOCUMENT}:${IMAGE_TAG}
                """

            }

        }

        stage('Update Kubeconfig') {

            steps {

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {

                    sh """
                    aws eks update-kubeconfig \\
                    --region ${AWS_REGION} \\
                    --name bbhealthapp-dev
                    """

                }

            }

        }
        stage('Deploy to Kubernetes') {

            steps {

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {

                    sh """
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/configmap.yaml
                        kubectl apply -f k8s/secret.yaml

                        kubectl apply -f k8s/master-service-deployment.yaml
                        kubectl apply -f k8s/register-service-deployment.yaml
                        kubectl apply -f k8s/document-service-deployment.yaml
                        kubectl apply -f k8s/frontend-deployment.yaml
                        kubectl apply -f k8s/ingress.yaml
                    """

                }

            }

        }

        stage('Verify Deployment') {

            steps {

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {

                    sh """
                        kubectl get nodes
                        kubectl get pods -n bbhealthapp
                        kubectl get svc -n bbhealthapp
                        kubectl get ingress -n bbhealthapp
                    """

                }

            }

        }

    }

    post {

        success {

            echo '========================================'
            echo 'BUILD AND DEPLOYMENT SUCCESSFUL'
            echo '========================================'

        }

        failure {

            echo '========================================'
            echo 'BUILD OR DEPLOYMENT FAILED'
            echo '========================================'

        }

        always {

            sh '''
            if command -v docker &> /dev/null; then
                docker image prune -f || echo "Docker prune failed, continuing..."
                docker system prune -f || echo "Docker system prune failed, continuing..."
            else
                echo "Docker not available, skipping cleanup"
            fi
            '''

        }

    }

}