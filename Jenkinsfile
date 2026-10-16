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

        stage('Clean Disk Space') {
            steps {
                sh '''
                    echo "Cleaning up disk space before build..."
                    
                    # Clean Docker
                    if command -v docker &> /dev/null; then
                        docker system prune -af --volumes || echo "Docker prune failed, continuing..."
                    fi
                    
                    # Clean Maven local repository old artifacts (keep last 30 days)
                    if [ -d ~/.m2/repository ]; then
                        find ~/.m2/repository -type f -mtime +30 -delete || echo "Maven cleanup failed, continuing..."
                    fi
                    
                    # Clean old Jenkins workspaces (keep last 7 days)
                    if [ -d /var/lib/jenkins/workspace ]; then
                        find /var/lib/jenkins/workspace -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || echo "Workspace cleanup failed, continuing..."
                    fi
                    
                    # Clean old Jenkins builds
                    if [ -d /var/lib/jenkins/jobs ]; then
                        find /var/lib/jenkins/jobs -type d -name "builds" -mtime +7 -exec rm -rf {} + 2>/dev/null || echo "Builds cleanup failed, continuing..."
                    fi
                    
                    # Clean temporary files
                    rm -rf /tmp/* 2>/dev/null || echo "Temp cleanup failed, continuing..."
                    
                    # Check disk space
                    df -h
                '''
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
            post {
                always {
                    sh 'docker system prune -f || echo "Docker prune failed, continuing..."'
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
            post {
                always {
                    sh 'docker system prune -f || echo "Docker prune failed, continuing..."'
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
            post {
                always {
                    sh 'docker system prune -f || echo "Docker prune failed, continuing..."'
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
            post {
                always {
                    sh 'docker system prune -f || echo "Docker prune failed, continuing..."'
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