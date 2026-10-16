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

        // Add local bin to PATH for locally installed tools
        PATH = "${env.HOME}/.local/bin:${env.HOME}/maven/bin:${env.PATH}"
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

                    # Create local bin directory
                    mkdir -p $HOME/.local/bin
                    export PATH=$HOME/.local/bin:$PATH

                    # Install Maven if not found
                    if [ ! -f "/usr/bin/mvn" ] && [ ! -f "$HOME/maven/bin/mvn" ] && [ ! -f "$HOME/.local/bin/mvn" ]; then
                        echo "Installing Maven to user directory..."
                        cd $HOME
                        curl -O https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
                        tar -xzf apache-maven-3.9.5-bin.tar.gz
                        mv apache-maven-3.9.5 maven
                        rm apache-maven-3.9.5-bin.tar.gz
                        export PATH=$HOME/maven/bin:$PATH
                        echo "export PATH=$HOME/maven/bin:\$PATH" >> $HOME/.bashrc
                        echo "Maven installed: $(mvn -version | head -n 1)"
                    else
                        echo "Maven already installed: $(mvn -version | head -n 1)"
                    fi

                    # Install AWS CLI if not found
                    if [ ! -f "/usr/bin/aws" ] && [ ! -f "$HOME/.local/bin/aws" ]; then
                        echo "Installing AWS CLI to user directory..."
                        cd /tmp
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        # Use Python to unzip if unzip is not available
                        if command -v unzip &> /dev/null; then
                            unzip -q awscliv2.zip
                        else
                            python3 -m zipfile -e awscliv2.zip .
                        fi
                        ./aws/install -i $HOME/.aws-cli -b $HOME/.local/bin
                        rm -rf aws awscliv2.zip
                        export PATH=$HOME/.local/bin:$PATH
                        echo "AWS CLI installed: $(aws --version)"
                    else
                        echo "AWS CLI already installed: $(aws --version)"
                    fi

                    # Install kubectl if not found
                    if [ ! -f "/usr/bin/kubectl" ] && [ ! -f "/usr/local/bin/kubectl" ] && [ ! -f "$HOME/.local/bin/kubectl" ]; then
                        echo "Installing kubectl to user directory..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl $HOME/.local/bin/kubectl
                        export PATH=$HOME/.local/bin:$PATH
                        echo "kubectl installed: $(kubectl version --client --short 2>/dev/null || echo 'version check failed')"
                    else
                        echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'version check failed')"
                    fi

                    # Check Docker (must be pre-installed with proper permissions)
                    if command -v docker &> /dev/null; then
                        echo "Docker found: $(docker --version)"
                        # Test docker access
                        if docker info &> /dev/null; then
                            echo "Docker access confirmed"
                        else
                            echo "WARNING: Jenkins user cannot access Docker. Please run: sudo usermod -aG docker jenkins && sudo systemctl restart jenkins"
                        fi
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

                    # Add local bin to PATH for subsequent stages
                    echo "export PATH=$HOME/.local/bin:$HOME/maven/bin:\$PATH" > $WORKSPACE/env_vars
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
                # Try Docker cleanup but don't fail on permission errors
                docker image prune -f 2>/dev/null || echo "Docker prune skipped (permission denied or no access)"
                docker system prune -f 2>/dev/null || echo "Docker system prune skipped (permission denied or no access)"
            else
                echo "Docker not available, skipping cleanup"
            fi
            '''

        }

    }

}