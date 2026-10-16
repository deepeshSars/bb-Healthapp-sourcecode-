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

        // AWS credentials - set these in Jenkins job configuration or as environment variables
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Required Tools') {
            steps {
                sh '''
                    echo "Installing required tools if missing..."

                    # Install Maven if not found
                    if ! command -v mvn &> /dev/null; then
                        echo "Installing Maven..."
                        sudo apt-get update
                        sudo apt-get install -y maven
                    else
                        echo "Maven already installed: $(mvn -version | head -n 1)"
                    fi

                    # Install AWS CLI if not found
                    if ! command -v aws &> /dev/null; then
                        echo "Installing AWS CLI..."
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip awscliv2.zip
                        sudo ./aws/install
                        rm -rf aws awscliv2.zip
                    else
                        echo "AWS CLI already installed: $(aws --version)"
                    fi

                    # Install kubectl if not found
                    if ! command -v kubectl &> /dev/null; then
                        echo "Installing kubectl..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                        rm kubectl
                    else
                        echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'version check failed')"
                    fi

                    # Fix Docker permissions
                    if command -v docker &> /dev/null; then
                        echo "Configuring Docker permissions..."
                        sudo usermod -aG docker jenkins 2>/dev/null || echo "Usermod failed (may need manual intervention)"
                        echo "Docker: $(docker --version)"
                    else
                        echo "ERROR: Docker not found. Please install Docker manually."
                        exit 1
                    fi

                    # Check Java
                    if ! command -v java &> /dev/null; then
                        echo "ERROR: Java not found. Please install Java (JDK 11 or higher)."
                        exit 1
                    else
                        echo "Java: $(java -version 2>&1 | head -n 1)"
                    fi
                '''
            }
        }



        stage('Login to AWS ECR') {
            steps {
                sh """
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                """
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
                sh """
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                aws eks update-kubeconfig \\
                --region ${AWS_REGION} \\
                --name bbhealthapp-dev
                """
            }

        }
        stage('Deploy to Kubernetes') {

            steps {
                sh """
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
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

        stage('Verify Deployment') {

            steps {
                sh """
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                kubectl get nodes
                kubectl get pods -n bbhealthapp
                kubectl get svc -n bbhealthapp
                kubectl get ingress -n bbhealthapp
                """
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