pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '591950085623.dkr.ecr.ap-south-1.amazonaws.com'
        CLUSTER_NAME = 'bbhealthapp-cluster'
        NAMESPACE = 'bbhealthapp'
        FRONTEND_IMAGE = 'bbhealthapp-frontend'
        MASTER_IMAGE = 'bbhealthapp-master-service'
        REGISTER_IMAGE = 'bbhealthapp-register-service'
        DOCUMENT_IMAGE = 'bbhealthapp-document-service'
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
                sh '''
                    git clone https://github.com/deepeshSars/bb-Healthapp-sourcecode-.git
                    git checkout main
                    git log -1
                '''
            }
        }

        stage('Configure AWS') {
            steps {
                sh """
                    aws configure set region ${AWS_REGION}
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                """
            }
        }

        stage('Provision Infrastructure') {
            when {
                expression { params.REBUILD_INFRA == true }
            }
            steps {
                dir('bb-Healthapp-sourcecode-/terraform') {
                    sh """
                        terraform init -input=false
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    """
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        dir('bb-Healthapp-sourcecode-/bbhealthapp-frontend') {
                            sh """
                                docker build -t ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
                            """
                        }
                    }
                }
                stage('Build Master Service') {
                    steps {
                        dir('bb-Healthapp-sourcecode-/bbhealthapp-backend/bbhealthapp-api-master') {
                            sh """
                                docker build -t ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${MASTER_IMAGE}:latest
                            """
                        }
                    }
                }
                stage('Build Register Service') {
                    steps {
                        dir('bb-Healthapp-sourcecode-/bbhealthapp-backend/bbhealthapp-api-register') {
                            sh """
                                docker build -t ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${REGISTER_IMAGE}:latest
                            """
                        }
                    }
                }
                stage('Build Document Service') {
                    steps {
                        dir('bb-Healthapp-sourcecode-/bbhealthapp-backend/bbhealthapp-api-document') {
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
                dir('bb-Healthapp-sourcecode-') {
                    sh """
                        # Run basic Docker image validation
                        docker images | grep bbhealthapp

                        # Test frontend build
                        docker run --rm ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} ls -la /usr/local/apache2/htdocs/ || true

                        # Test backend services health check (if health endpoints exist)
                        # docker run --rm ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} curl -f http://localhost:8080/actuator/health || true
                    """
                }
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
                dir('bb-Healthapp-sourcecode-') {
                    sh """
                        aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}

                        # Create namespace if it doesn't exist
                        kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

                        # Apply Kubernetes manifests
                        kubectl apply -f k8s/ -n ${NAMESPACE}
                    """
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.SKIP_DEPLOY == false }
            }
            steps {
                sh """
                    aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}

                    # Wait for pods to be ready
                    kubectl wait --for=condition=ready pod -l app=bbhealthapp -n ${NAMESPACE} --timeout=300s

                    # Get pod status
                    kubectl get pods -n ${NAMESPACE}
                    kubectl get services -n ${NAMESPACE}
                    kubectl get ingress -n ${NAMESPACE}
                """
            }
        }

        stage('Integration Tests') {
            when {
                expression { params.SKIP_DEPLOY == false && params.RUN_TESTS == true }
            }
            steps {
                script {
                    try {
                        sh """
                            # Get Load Balancer URL
                            LB_URL=\$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
                            echo "Load Balancer URL: \$LB_URL"

                            # Basic connectivity test
                            curl -f http://\$LB_URL/ || echo "Frontend test failed"
                            curl -f http://\$LB_URL/api/master/actuator/health || echo "Master service health check failed"
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
            }
        }
        unstable {
            echo "⚠️ Deployment completed with warnings"
        }
        always {
            script {
                sh """
                    # Clean workspace
                    rm -rf healthapp-aws
                """
                echo "Pipeline execution completed"
            }
        }
    }
}
