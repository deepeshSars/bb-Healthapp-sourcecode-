pipeline {
    agent any

    options {
        // Discard old builds to save space
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '3'))
    }

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

        stage('Pre-Build Cleanup') {
            steps {
                sh '''
                    echo "========================================"
                    echo "INITIAL DISK SPACE CHECK"
                    echo "========================================"
                    df -h

                    echo ""
                    echo "========================================"
                    echo "AGGRESSIVE DISK CLEANUP"
                    echo "========================================"

                    # Clean Docker (most aggressive)
                    if command -v docker &> /dev/null; then
                        echo "Cleaning Docker..."
                        docker system prune -af --volumes || echo "Docker prune failed"
                        docker image prune -af || echo "Docker image prune failed"
                    fi

                    # Clean Jenkins workspace (current workspace)
                    echo "Cleaning current workspace..."
                    rm -rf ./* || echo "Workspace cleanup failed"

                    # Clean other Jenkins workspaces
                    if [ -d /var/lib/jenkins/workspace ]; then
                        echo "Cleaning old Jenkins workspaces..."
                        find /var/lib/jenkins/workspace -mindepth 1 -maxdepth 1 -type d ! -name "$(basename $WORKSPACE)" -exec rm -rf {} + 2>/dev/null || echo "Other workspace cleanup failed"
                    fi

                    # Clean Jenkins logs
                    if [ -d /var/lib/jenkins/logs ]; then
                        echo "Cleaning Jenkins logs..."
                        find /var/lib/jenkins/logs -type f -mtime +3 -delete 2>/dev/null || echo "Log cleanup failed"
                    fi

                    # Clean Jenkins cache
                    if [ -d /var/lib/jenkins/cache ]; then
                        echo "Cleaning Jenkins cache..."
                        find /var/lib/jenkins/cache -type f -mtime +7 -delete 2>/dev/null || echo "Cache cleanup failed"
                    fi

                    # Clean Maven local repository
                    if [ -d ~/.m2/repository ]; then
                        echo "Cleaning Maven repository..."
                        find ~/.m2/repository -type f -mtime +7 -delete 2>/dev/null || echo "Maven cleanup failed"
                    fi

                    # Clean temporary files
                    echo "Cleaning temp files..."
                    rm -rf /tmp/* 2>/dev/null || echo "Temp cleanup failed"

                    # Clean system cache
                    if command -v apt-get &> /dev/null; then
                        echo "Cleaning apt cache..."
                        apt-get clean || echo "Apt clean failed"
                        apt-get autoclean || echo "Apt autoclean failed"
                    fi

                    echo ""
                    echo "========================================"
                    echo "DISK SPACE AFTER CLEANUP"
                    echo "========================================"
                    df -h
                '''
            }
        }

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
                sh 'echo "========================================"'
                sh 'echo "DISK SPACE AFTER TOOL CHECK"'
                sh 'echo "========================================"'
                sh 'df -h'
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
                    sh '''
                        docker system prune -f || echo "Docker prune failed, continuing..."
                        echo "========================================"
                        echo "DISK SPACE AFTER FRONTEND BUILD"
                        echo "========================================"
                        df -h
                    '''
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
                    sh '''
                        docker system prune -f || echo "Docker prune failed, continuing..."
                        echo "========================================"
                        echo "DISK SPACE AFTER MASTER BUILD"
                        echo "========================================"
                        df -h
                    '''
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
                    sh '''
                        docker system prune -f || echo "Docker prune failed, continuing..."
                        echo "========================================"
                        echo "DISK SPACE AFTER REGISTER BUILD"
                        echo "========================================"
                        df -h
                    '''
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
                    sh '''
                        docker system prune -f || echo "Docker prune failed, continuing..."
                        echo "========================================"
                        echo "DISK SPACE AFTER DOCUMENT BUILD"
                        echo "========================================"
                        df -h
                    '''
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
            post {
                always {
                    sh '''
                        echo "========================================"
                        echo "DISK SPACE AFTER PUSH"
                        echo "========================================"
                        df -h
                    '''
                }
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

                echo "========================================"
                echo "DEPLOYMENT VERIFICATION"
                echo "========================================"

                echo ""
                echo "1. Checking Kubernetes Nodes..."
                kubectl get nodes

                echo ""
                echo "2. Checking Pods in bbhealthapp namespace..."
                kubectl get pods -n bbhealthapp

                echo ""
                echo "3. Checking Services in bbhealthapp namespace..."
                kubectl get svc -n bbhealthapp

                echo ""
                echo "4. Checking Ingress in bbhealthapp namespace..."
                kubectl get ingress -n bbhealthapp

                echo ""
                echo "5. Verifying all pods are running..."
                POD_STATUS=\$(kubectl get pods -n bbhealthapp -o jsonpath='{.items[*].status.phase}')
                if echo "\$POD_STATUS" | grep -v "Running"; then
                    echo "WARNING: Some pods are not in Running state"
                    kubectl get pods -n bbhealthapp
                else
                    echo "SUCCESS: All pods are running"
                fi

                echo ""
                echo "6. Checking pod restart counts..."
                kubectl get pods -n bbhealthapp

                echo ""
                echo "========================================"
                echo "DEPLOYMENT VERIFICATION COMPLETE"
                echo "========================================"
                """
            }
            post {
                always {
                    sh '''
                        echo "========================================"
                        echo "FINAL DISK SPACE CHECK"
                        echo "========================================"
                        df -h
                    '''
                }
            }

        }

    }

    post {

        success {

            echo '========================================'
            echo 'BUILD AND DEPLOYMENT SUCCESSFUL'
            echo '========================================'
            echo ''
            echo 'To verify deployment:'
            echo '1. Check Jenkins console output - look for "SUCCESS: All pods are running"'
            echo '2. All pods in bbhealthapp namespace should show "Running" status'
            echo '3. Pod restart counts should be 0 or low'
            echo '4. Ingress should show proper addresses'
            echo '5. Access your application via the Ingress URL'
            echo ''
            echo 'Kubernetes commands to check manually:'
            echo '  kubectl get pods -n bbhealthapp'
            echo '  kubectl get svc -n bbhealthapp'
            echo '  kubectl get ingress -n bbhealthapp'
            echo '  kubectl logs -n bbhealthapp <pod-name>'
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