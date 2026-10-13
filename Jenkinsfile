pipeline {
    agent {
        docker {
            image 'maven:3.9-eclipse-temurin-21'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        // AWS Region
        AWS_REGION = 'ap-south-1'
        
        // ECR Repository Names
        ECR_REPO_MASTER = 'bbhealthapp-dev-master-service'
        ECR_REPO_REGISTER = 'bbhealthapp-dev-register-service'
        ECR_REPO_DOCUMENT = 'bbhealthapp-dev-document-service'
        ECR_REPO_FRONTEND = 'bbhealthapp-dev-frontend'
        
        // Kubernetes Namespace
        K8S_NAMESPACE = 'bbhealthapp'
        
        // Image Tag (using build number and git commit)
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '=== Checkout Stage ==='
                    echo 'Checking out source code from repository'
                    checkout scm
                    sh 'git rev-parse HEAD > GIT_COMMIT'
                    env.GIT_COMMIT = readFile('GIT_COMMIT').trim()
                    echo "Git Commit: ${env.GIT_COMMIT}"
                    echo "Build Number: ${env.BUILD_NUMBER}"
                    echo "Image Tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build Frontend') {
            steps {
                script {
                    echo '=== Build Frontend Stage ==='
                    // Install Node.js and npm
                    sh '''
                        curl -fsSL https://deb.nodesource.com/setup_18.x | sh -
                        apt-get install -y nodejs
                    '''
                    dir('bbhealthapp-frontend') {
                        echo 'Installing frontend dependencies...'
                        sh 'npm install'

                        echo 'Building frontend application...'
                        sh 'npm run build'

                        echo 'Frontend build completed successfully'
                    }
                }
            }
        }

        stage('Build Backend Services') {
            parallel {
                stage('Build Master Service') {
                    steps {
                        script {
                            echo '=== Build Master Service ==='
                            dir('bbhealthapp-backend/bbhealthapp-api-master') {
                                echo 'Building master service with Maven...'
                                sh 'mvn clean package -DskipTests'
                                echo 'Master service build completed'
                            }
                        }
                    }
                }
                stage('Build Register Service') {
                    steps {
                        script {
                            echo '=== Build Register Service ==='
                            dir('bbhealthapp-backend/bbhealthapp-api-register') {
                                echo 'Building register service with Maven...'
                                sh 'mvn clean package -DskipTests'
                                echo 'Register service build completed'
                            }
                        }
                    }
                }
                stage('Build Document Service') {
                    steps {
                        script {
                            echo '=== Build Document Service ==='
                            dir('bbhealthapp-backend/bbhealthapp-api-document') {
                                echo 'Building document service with Maven...'
                                sh 'mvn clean package -DskipTests'
                                echo 'Document service build completed'
                            }
                        }
                    }
                }
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                script {
                    echo '=== Configure AWS Credentials ==='
                    // Install AWS CLI and kubectl
                    sh '''
                        apt-get update && apt-get install -y unzip curl
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip awscliv2.zip
                        ./aws/install
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl /usr/local/bin/
                    '''
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        // Test AWS credentials
                        sh '''
                            aws sts get-caller-identity
                        '''
                        echo 'AWS credentials validated successfully'
                        
                        // Login to ECR
                        sh '''
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_REGION}.amazonaws.com
                        '''
                        echo 'ECR login successful'
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    echo '=== Build Docker Images Stage ==='
                    
                    // Get AWS Account ID
                    env.AWS_ACCOUNT_ID = sh(
                        script: 'aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()
                    
                    echo "AWS Account ID: ${env.AWS_ACCOUNT_ID}"
                    
                    // Build Frontend Image
                    dir('bbhealthapp-frontend') {
                        echo "Building frontend Docker image..."
                        sh """
                            docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONTEND}:${IMAGE_TAG} .
                            docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONTEND}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONTEND}:latest
                        """
                        echo "Frontend Docker image built successfully"
                    }
                    
                    // Build Master Service Image
                    dir('bbhealthapp-backend/bbhealthapp-api-master') {
                        echo "Building master service Docker image..."
                        sh """
                            docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_MASTER}:${IMAGE_TAG} .
                            docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_MASTER}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_MASTER}:latest
                        """
                        echo "Master service Docker image built successfully"
                    }
                    
                    // Build Register Service Image
                    dir('bbhealthapp-backend/bbhealthapp-api-register') {
                        echo "Building register service Docker image..."
                        sh """
                            docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_REGISTER}:${IMAGE_TAG} .
                            docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_REGISTER}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_REGISTER}:latest
                        """
                        echo "Register service Docker image built successfully"
                    }
                    
                    // Build Document Service Image
                    dir('bbhealthapp-backend/bbhealthapp-api-document') {
                        echo "Building document service Docker image..."
                        sh """
                            docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_DOCUMENT}:${IMAGE_TAG} .
                            docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_DOCUMENT}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_DOCUMENT}:latest
                        """
                        echo "Document service Docker image built successfully"
                    }
                }
            }
        }

        stage('Push Images to ECR') {
            steps {
                script {
                    echo '=== Push Images to ECR Stage ==='
                    
                    // Push Frontend
                    echo "Pushing frontend image to ECR..."
                    sh """
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONTEND}:${IMAGE_TAG}
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONTEND}:latest
                    """
                    echo "Frontend image pushed successfully"
                    
                    // Push Master Service
                    echo "Pushing master service image to ECR..."
                    sh """
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_MASTER}:${IMAGE_TAG}
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_MASTER}:latest
                    """
                    echo "Master service image pushed successfully"
                    
                    // Push Register Service
                    echo "Pushing register service image to ECR..."
                    sh """
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_REGISTER}:${IMAGE_TAG}
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_REGISTER}:latest
                    """
                    echo "Register service image pushed successfully"
                    
                    // Push Document Service
                    echo "Pushing document service image to ECR..."
                    sh """
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_DOCUMENT}:${IMAGE_TAG}
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_DOCUMENT}:latest
                    """
                    echo "Document service image pushed successfully"
                    
                    echo 'All images pushed to ECR successfully'
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    echo '=== Deploy to EKS Stage ==='
                    
                    // Configure kubectl with EKS credentials
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh """
                            aws eks update-kubeconfig --name bbhealthapp-eks --region ${AWS_REGION}
                        """
                        echo 'kubectl configured for EKS cluster'
                    }
                    
                    // Update Kubernetes deployments with new image tags
                    dir('k8s') {
                        echo 'Updating Kubernetes deployments...'
                        
                        // Update master service deployment
                        sh """
                            kubectl set image deployment/master-service \
                            master-service=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_MASTER}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE}
                        """
                        
                        // Update register service deployment
                        sh """
                            kubectl set image deployment/register-service \
                            register-service=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_REGISTER}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE}
                        """
                        
                        // Update document service deployment
                        sh """
                            kubectl set image deployment/document-service \
                            document-service=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_DOCUMENT}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE}
                        """
                        
                        // Update frontend deployment
                        sh """
                            kubectl set image deployment/frontend \
                            frontend=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONTEND}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE}
                        """
                        
                        echo 'Deployments updated successfully'
                        
                        // Wait for deployments to roll out
                        echo 'Waiting for deployments to roll out...'
                        sh """
                            kubectl rollout status deployment/master-service -n ${K8S_NAMESPACE} --timeout=5m
                            kubectl rollout status deployment/register-service -n ${K8S_NAMESPACE} --timeout=5m
                            kubectl rollout status deployment/document-service -n ${K8S_NAMESPACE} --timeout=5m
                            kubectl rollout status deployment/frontend -n ${K8S_NAMESPACE} --timeout=5m
                        """
                        echo 'All deployments rolled out successfully'
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    echo '=== Verify Deployment Stage ==='
                    
                    sh """
                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl get services -n ${K8S_NAMESPACE}
                    """
                    
                    echo 'Deployment verification completed'
                }
            }
        }

        stage('Clean Up') {
            steps {
                script {
                    echo '=== Clean Up Stage ==='
                    echo 'Cleaning up local Docker images...'
                    sh 'docker system prune -f'
                    echo 'Cleanup completed'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
            echo "Deployed image tag: ${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
        always {
            echo 'Pipeline execution finished'
            cleanWs()
        }
    }
}
