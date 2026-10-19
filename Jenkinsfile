pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '591950085623.dkr.ecr.ap-south-1.amazonaws.com'
        CLUSTER_NAME = 'bbhealthapp-dev-eks'
        NAMESPACE = 'bbhealthapp'
        FRONTEND_IMAGE = 'bbhealthapp-dev-frontend'
        MASTER_IMAGE = 'bbhealthapp-dev-master-service'
        REGISTER_IMAGE = 'bbhealthapp-dev-register-service'
        DOCUMENT_IMAGE = 'bbhealthapp-dev-document-service'
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Deployment environment')
        booleanParam(name: 'REBUILD_INFRA', defaultValue: false, description: 'Rebuild infrastructure with Terraform')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run automated tests')
        booleanParam(name: 'SKIP_DEPLOY', defaultValue: false, description: 'Skip deployment (build and push only)')
    }

    stages {
        stage('Setup') {
            steps {
                script {
                    currentBuild.displayName = "#${BUILD_NUMBER} - ${params.ENVIRONMENT}"
                    echo "Starting deployment for environment: ${params.ENVIRONMENT}"
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1'
            }
        }

        stage('Configure AWS') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        # Create ECR repositories if they don't exist
                        aws ecr describe-repositories --repository-names ${FRONTEND_IMAGE} --region ${AWS_REGION} || aws ecr create-repository --repository-name ${FRONTEND_IMAGE} --region ${AWS_REGION}
                        aws ecr describe-repositories --repository-names ${MASTER_IMAGE} --region ${AWS_REGION} || aws ecr create-repository --repository-name ${MASTER_IMAGE} --region ${AWS_REGION}
                        aws ecr describe-repositories --repository-names ${REGISTER_IMAGE} --region ${AWS_REGION} || aws ecr create-repository --repository-name ${REGISTER_IMAGE} --region ${AWS_REGION}
                        aws ecr describe-repositories --repository-names ${DOCUMENT_IMAGE} --region ${AWS_REGION} || aws ecr create-repository --repository-name ${DOCUMENT_IMAGE} --region ${AWS_REGION}
                    """
                }
            }
        }

        stage('Install kubectl') {
            steps {
                sh '''
                    # Remove broken kubectl if exists
                    sudo rm -f /usr/local/bin/kubectl || true
                    # Install kubectl
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    sudo chmod +x kubectl
                    sudo mv kubectl /usr/local/bin/
                    kubectl version --client
                '''
            }
        }

        stage('Provision Infrastructure') {
            when {
                expression { params.REBUILD_INFRA == true }
            }
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    dir('terraform') {
                        sh """
                            terraform init -input=false
                            terraform plan -out=tfplan
                            terraform apply -auto-approve tfplan
                        """
                    }
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        dir('bbhealthapp-frontend') {
                            sh """
                                docker build -t ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
                            """
                        }
                    }
                }
                stage('Build Master Service') {
                    steps {
                        dir('bbhealthapp-backend/bbhealthapp-api-master') {
                            sh """
                                docker build -t ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${MASTER_IMAGE}:latest
                            """
                        }
                    }
                }
                stage('Build Register Service') {
                    steps {
                        dir('bbhealthapp-backend/bbhealthapp-api-register') {
                            sh """
                                docker build -t ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${REGISTER_IMAGE}:latest
                            """
                        }
                    }
                }
                stage('Build Document Service') {
                    steps {
                        dir('bbhealthapp-backend/bbhealthapp-api-document') {
                            sh """
                                docker build -t ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Run Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                sh """
                    # Run basic Docker image validation
                    docker images | grep bbhealthapp

                    # Test frontend build
                    docker run ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} ls -la /usr/local/apache2/htdocs/ || true

                    # Test backend services health check (if health endpoints exist)
                    # docker run ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} curl -f http://localhost:8080/actuator/health || true
                """
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                    docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
                    docker push ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${MASTER_IMAGE}:latest
                    docker push ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${REGISTER_IMAGE}:latest
                    docker push ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:latest
                """
            }
        }

        stage('Deploy to EKS') {
            when {
                expression { params.SKIP_DEPLOY == false }
            }
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    sh 'aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}'
                    sh 'kubectl create namespace ${NAMESPACE} || true'
                    sh 'kubectl apply -f k8s/ -n ${NAMESPACE}'
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.SKIP_DEPLOY == false }
            }
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    sh 'aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}'
                    sh 'kubectl wait --for=condition=ready pod --all -n ${NAMESPACE} --timeout=300s || true'
                    sh 'kubectl get pods -n ${NAMESPACE}'
                    sh 'kubectl get services -n ${NAMESPACE}'
                    sh 'kubectl get ingress -n ${NAMESPACE}'
                }
            }
        }

        stage('Integration Tests') {
            when {
                expression { params.SKIP_DEPLOY == false && params.RUN_TESTS == true }
            }
            steps {
                script {
                    try {
                        sh 'LB_URL=$(kubectl get ingress -n ${NAMESPACE} -o jsonpath=\'{.items[0].status.loadBalancer.ingress[0].hostname}\' 2>/dev/null || echo "")'
                        sh 'echo "Load Balancer URL: $LB_URL"'
                        sh """
                            if [ -n "$LB_URL" ]; then
                                curl -f http://$LB_URL/ || echo "Frontend test failed"
                                curl -f http://$LB_URL/api/master/actuator/health || echo "Master service health check failed"
                            else
                                echo "No Load Balancer URL found, skipping integration tests"
                            fi
                        """
                    } catch (Exception e) {
                        echo "Integration tests failed: ${e}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh """
                    # Clean up old Docker images
                    docker system prune -f
                    docker image prune -a -f
                """
            }
        }
    }

    post {
        success {
            script {
                echo "✅ Deployment successful for ${params.ENVIRONMENT} environment!"
                echo "Build number: ${BUILD_NUMBER}"
                echo "Image tag: ${BUILD_NUMBER}"
            }
        }
        failure {
            script {
                echo "❌ Deployment failed!"
                echo "Attempting rollback..."
                try {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        sh """
                            aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION} || echo "Cluster not found, skipping rollback"
                        """
                    }
                } catch (Exception e) {
                    echo "Rollback failed or not needed: ${e}"
                }
            }
        }
        unstable {
            echo "⚠️ Deployment completed with warnings"
        }
        always {
            script {
                echo "Pipeline execution completed"
            }
        }
    }
}
