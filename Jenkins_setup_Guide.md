# BBHealthApp - Jenkins CI/CD Deployment to EKS Guide

This guide will help you set up Jenkins for continuous integration and continuous deployment (CI/CD) to deploy the BBHealthApp to AWS EKS.

---

## Prerequisites

Before you begin, ensure you have the following:

### 1. Existing EKS Cluster
- EKS cluster should already be created (from Terraform phase)
- Cluster should be in "ACTIVE" status
- Node groups should be running

### 2. Jenkins Server
- Jenkins installed (can be on EC2, on-premises, or Jenkins Cloud)
- Jenkins version 2.x or higher
- Admin access to Jenkins

### 3. Required Software on Jenkins Agent
- **AWS CLI** - For interacting with AWS services
- **Docker** - For building and pushing Docker images
- **kubectl** - For deploying to Kubernetes
- **Helm** - For Helm chart deployment
- **Terraform** - For infrastructure provisioning (optional, if using Terraform in pipeline)
- **Git** - For cloning source code

### 4. AWS Credentials
- AWS Access Key ID with appropriate permissions
- AWS Secret Access Key
- IAM user/role with permissions for:
  - EKS (cluster access)
  - ECR (push/pull images)
  - EC2 (if provisioning infrastructure)
  - IAM (if creating roles)

### 5. Source Code Repository
- Project code hosted on GitHub, GitLab, or other Git repository
- Jenkins should have access to clone the repository

---

## Jenkins Setup

### Step 1: Install Required Plugins

Log in to Jenkins and install the following plugins:

1. **Pipeline** - For defining CI/CD pipelines as code
2. **Git** - For Git integration
3. **Docker Pipeline** - For Docker operations
4. **AWS Steps** - For AWS CLI integration
5. **Credentials Binding** - For using credentials in pipelines
6. **Blue Ocean** (optional) - For better pipeline visualization

**To install plugins:**
1. Go to **Manage Jenkins** → **Plugins**
2. Click **Available** tab
3. Search for each plugin
4. Select and click **Install without restart**

### Step 2: Configure Jenkins Credentials

Add the following credentials in Jenkins:

**AWS Credentials:**
1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **Add Credentials**
3. Select **AWS Credentials**
4. Fill in:
   - **ID**: `aws-credentials`
   - **Access Key ID**: Your AWS access key
   - **Secret Access Key**: Your AWS secret key
5. Click **Create**

**Docker Registry Credentials (ECR):**
1. Click **Add Credentials**
2. Select **Username with password**
3. Fill in:
   - **ID**: `ecr-credentials`
   - **Username**: AWS (for ECR)
   - **Password**: Get from AWS CLI: `aws ecr get-login-password --region us-west-2`
4. Click **Create**

**Git Credentials (if private repository):**
1. Click **Add Credentials**
2. Select **Username with password**
3. Fill in:
   - **ID**: `git-credentials`
   - **Username**: Your Git username
   - **Password**: Your Git personal access token or password
4. Click **Create**

### Step 3: Configure Global Tool Configuration

Configure the required tools in Jenkins:

1. Go to **Manage Jenkins** → **Global Tool Configuration**

**AWS CLI:**
- Scroll to **AWS CLI** section
- Click **AWS CLI installations**
- Click **Add AWS CLI**
- **Name**: `AWSCLI`
- Click **Save**

**Docker:**
- Scroll to **Docker** section
- Click **Docker installations**
- Click **Add Docker**
- **Name**: `Docker`
- Click **Save**

**Helm:**
- Scroll to **Helm** section
- Click **Add Helm**
- **Name**: `Helm`
- Click **Save**

**Terraform:**
- Scroll to **Terraform** section
- Click **Add Terraform**
- **Name**: `Terraform`
- Click **Save**

### Step 4: Configure Jenkins Agent

Ensure your Jenkins agent has the required software installed:

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Docker
sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installations
aws --version
docker --version
kubectl version --client
helm version
terraform version
```

---

## Jenkins Pipeline Configuration

### Step 1: Create Jenkinsfile

Create a `Jenkinsfile` in the root of your project directory. This file defines the CI/CD pipeline stages.

**Pipeline Stages:**

1. **Checkout** - Clones the Git repository
2. **Configure AWS** - Logs in to AWS ECR
3. **Build Docker Images** - Builds Docker images for all services
4. **Push to ECR** - Pushes images to AWS ECR
5. **Deploy to EKS** - Deploys application to EKS using Helm

### Step 2: Create Your Jenkinsfile

Create a new file named `Jenkinsfile` in your project root. Write the pipeline configuration based on the stages described below.

**Required Pipeline Stages:**

1. **Environment Variables** - Define your ECR registry, image names, AWS region, and cluster name
2. **Checkout Stage** - Clone the Git repository using `checkout scm`
3. **Configure AWS Stage** - Use AWS credentials to configure AWS CLI and login to ECR
4. **Build Docker Images Stage** - Build Docker images for frontend, master service, register service, and document service
5. **Push to ECR Stage** - Push all images to AWS ECR with build number tags
6. **Deploy to EKS Stage** - Update kubeconfig and deploy using Helm

**Key Points:**
- Use `withCredentials([aws(credentialsId: 'aws-credentials')])` for AWS authentication
- Use `${BUILD_NUMBER}` for image versioning
- Use `helm upgrade --install` for deployment
- Add `post` section for cleanup and notifications

### Step 3: Create Jenkins Pipeline Job

1. Log in to Jenkins
2. Click **New Item**
3. Enter **Item name**: `bbhealthapp-eks-deployment`
4. Select **Pipeline**
5. Click **OK**

**Pipeline Configuration:**
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: Your Git repository URL
- **Credentials**: Select your Git credentials (if private)
- **Branch**: `*/main` (or your branch)
- **Script Path**: `Jenkinsfile` (the file you created in Step 2)

Click **Save**

---

## Running the Pipeline

### Manual Trigger

1. Go to the pipeline job `bbhealthapp-eks-deployment`
2. Click **Build Now**
3. Click on the build number to view the progress
4. Monitor each stage execution

### Automatic Trigger (Webhook)

Configure Git repository webhook to trigger Jenkins on push:

**GitHub:**
1. Go to your GitHub repository
2. Click **Settings** → **Webhooks**
3. Click **Add webhook**
4. **Payload URL**: `http://YOUR_JENKINS_URL/github-webhook/`
5. **Content type**: `application/json`
6. Select **Just the push event**
7. Click **Add webhook**

**GitLab:**
1. Go to your GitLab project
2. Click **Settings** → **Webhooks**
3. **URL**: `http://YOUR_JENKINS_URL/project/bbhealthapp-eks-deployment`
4. Select **Push events**
5. Click **Add webhook**

---

## Pipeline Stages Explained

### Stage 1: Checkout
- Clones the Git repository
- Checks out the specified branch
- Prepares the workspace for build

### Stage 2: Configure AWS
- Configures AWS CLI with credentials
- Logs in to AWS ECR
- Authenticates Docker with ECR registry

### Stage 3: Build Docker Images
- Builds Docker images for all services:
  - Frontend (React)
  - Master Service (Spring Boot)
  - Register Service (Spring Boot)
  - Document Service (Spring Boot)
- Tags images with build number and `latest`

### Stage 4: Push to ECR
- Pushes all Docker images to AWS ECR
- Images are tagged with build number for versioning
- `latest` tag is also pushed for convenience

### Stage 5: Deploy to EKS
- Updates kubeconfig to connect to EKS cluster
- Uses Helm to deploy/upgrade the application
- Deploys to `bbhealthapp` namespace
- Uses the build number as image tag

---

## Monitoring the Pipeline

### View Pipeline Execution

1. Click on the build number
2. View the stage progress
3. Click on each stage to see detailed logs
4. Check for any errors or warnings

### View Console Output

- Click **Console Output** to see the full execution log
- Search for specific errors or warnings
- Download logs for analysis

### Blue Ocean View (if installed)

1. Click **Open Blue Ocean** in Jenkins
2. Visual representation of pipeline execution
- Click on stages to see details
- Better visualization of parallel stages

---

## Troubleshooting

### AWS Credentials Error

**Error:** `Unable to locate credentials`

**Solution:**
1. Verify AWS credentials are correctly configured in Jenkins
2. Check credentials ID matches in Jenkinsfile
3. Ensure IAM user has required permissions

### Docker Build Error

**Error:** `Cannot connect to the Docker daemon`

**Solution:**
1. Ensure Docker is running on Jenkins agent
2. Add Jenkins user to docker group: `sudo usermod -aG docker jenkins`
3. Restart Jenkins service

### ECR Login Error

**Error:** `Error: Cannot perform an interactive login from a non-TTY device`

**Solution:**
1. Use `aws ecr get-login-password` instead of `aws ecr get-login`
2. Ensure AWS CLI is properly configured
3. Verify region is correct

### Image Push Error

**Error:** `no basic auth credentials`

**Solution:**
1. Verify Docker is logged in to ECR
2. Check ECR repository permissions
3. Ensure IAM user has `ecr:Push` permission

### EKS Connection Error

**Error:** `error: You must be logged in to the server`

**Solution:**
1. Verify kubeconfig is updated: `aws eks update-kubeconfig`
2. Check IAM user has EKS permissions
3. Ensure cluster name and region are correct

### Helm Deployment Error

**Error:** `Error: failed to download "stable/chart-name"`

**Solution:**
1. Ensure Helm is installed on Jenkins agent
2. Update Helm repositories: `helm repo update`
3. Check Helm chart path is correct

### Terraform Error

**Error:** `Error: Could not satisfy plugin requirements`

**Solution:**
1. Run `terraform init` to download plugins
2. Check Terraform version compatibility
3. Verify Terraform is installed on Jenkins agent

---

## Jenkins Best Practices

### 1. Use Pipeline as Code
- Store Jenkinsfile in Git repository
- Version control your pipeline
- Easy to review and modify

### 2. Use Credentials Properly
- Never hardcode credentials in Jenkinsfile
- Use Jenkins credentials store
- Use credential binding plugin

### 3. Implement Notifications
- Add email notifications for build failures
- Configure Slack or Microsoft Teams integration
- Set up build status notifications

### 4. Use Parameters
- Make pipeline configurable with parameters
- Allow environment selection (dev, staging, prod)
- Enable custom image tags

### 5. Implement Cleanup
- Clean workspace after build
- Remove old Docker images
- Clean up temporary files

### 6. Use Parallel Stages
- Run independent stages in parallel
- Reduce overall build time
- Example: Build images in parallel

### 7. Add Health Checks
- Verify deployment success
- Check pod status after deployment
- Test application endpoints

### 8. Implement Rollback
- Add rollback stage on failure
- Use Helm rollback capability
- Keep previous deployments

---

## Advanced Pipeline Features

### Parameterized Pipeline

Add parameters to make pipeline configurable:

```groovy
pipeline {
    agent any
    
    parameters {
        string(name: 'AWS_REGION', defaultValue: 'us-west-2', description: 'AWS Region')
        string(name: 'CLUSTER_NAME', defaultValue: 'bbhealthapp-cluster', description: 'EKS Cluster Name')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Environment')
    }
    
    stages {
        stage('Deploy') {
            steps {
                sh """
                    helm upgrade --install bbhealthapp ./helm/bbhealthapp \\
                      --namespace bbhealthapp \\
                      --create-namespace \\
                      --set image.registry=${ECR_REGISTRY} \\
                      --set image.tag=${BUILD_NUMBER} \\
                      --set environment=${params.ENVIRONMENT}
                """
            }
        }
    }
}
```

### Parallel Execution

Run stages in parallel:

```groovy
stage('Build Images') {
    parallel {
        stage('Build Frontend') {
            steps {
                sh 'docker build -t frontend .'
            }
        }
        stage('Build Backend') {
            steps {
                sh 'docker build -t backend .'
            }
        }
    }
}
```

### Conditional Stages

Run stages based on conditions:

```groovy
stage('Deploy to Production') {
    when {
        branch 'main'
    }
    steps {
        sh 'helm upgrade --install bbhealthapp ./helm/bbhealthapp'
    }
}
```

### Post-Deployment Tests

Add tests after deployment:

```groovy
stage('Health Check') {
    steps {
        sh '''
            kubectl wait --for=condition=ready pod -l app=frontend -n bbhealthapp --timeout=300s
            kubectl get pods -n bbhealthapp
        '''
    }
}
```

---

## Cleanup

### Delete Jenkins Job

1. Go to the pipeline job
2. Click **Configure**
3. Scroll down and click **Delete**
4. Confirm deletion

### Clean Jenkins Workspace

```groovy
post {
    always {
        cleanWs()
    }
}
```

### Remove Docker Images

```groovy
post {
    always {
        sh 'docker system prune -f'
    }
}
```

---

## Report Requirements

### 1. Jenkins Setup
- Screenshots of Jenkins dashboard
- Screenshots of installed plugins
- Screenshots of configured credentials
- Screenshots of global tool configuration

### 2. Pipeline Configuration
- Screenshots of Jenkins pipeline job configuration
- Screenshots of Jenkinsfile content
- Explanation of each pipeline stage
- How credentials are used in the pipeline

### 3. Pipeline Execution
- Screenshots of pipeline execution stages
- Screenshots of successful build
- Screenshots of each stage logs
- Time taken for each stage

### 4. Docker Build and Push
- Screenshots of Docker build logs
- Screenshots of ECR repositories with pushed images
- Explanation of image tagging strategy (BUILD_NUMBER)
- How image versioning works

### 5. Helm Deployment
- Screenshots of Helm deployment logs
- Screenshots of Helm release status
- Screenshots of `helm list` output
- Explanation of Helm chart usage

### 6. EKS Verification
- Screenshots of `kubectl get pods` after deployment
- Screenshots of application running in browser
- Screenshots of Load Balancer URL
- Verification of successful deployment

### 7. CI/CD Concepts
- Explanation of CI (Continuous Integration)
- Explanation of CD (Continuous Deployment)
- Benefits of using Jenkins for CI/CD
- How Jenkins automates the deployment process

### 8. Troubleshooting
- Any errors encountered during pipeline execution
- How you resolved each error
- Jenkins logs checked for debugging
- Lessons learned from troubleshooting

### 9. Pipeline Optimization
- Any optimizations made to the pipeline
- Parallel stages implemented
- Build time improvements
- Best practices followed

### 10. Learning Outcomes
- Top 3 things you learned from this exercise
- Understanding of CI/CD pipelines
- Experience with Jenkins automation
- How CI/CD improves development workflow

---

## Learning Outcomes

By completing this phase, students will learn:

1. **CI/CD Concepts**
   - Continuous Integration
   - Continuous Deployment
   - Pipeline automation
   - Build and release management

2. **Jenkins**
   - Jenkins installation and configuration
   - Pipeline as Code (Jenkinsfile)
   - Jenkins credentials management
   - Jenkins plugins and tools

3. **Docker in CI/CD**
   - Building Docker images in pipelines
   - Pushing images to registries
   - Image versioning and tagging
   - Docker registry authentication

4. **Kubernetes Deployment Automation**
   - Helm chart deployment
   - kubectl integration
   - Rolling updates and rollbacks
   - Health checks and monitoring

5. **AWS Integration**
   - AWS CLI integration with Jenkins
   - ECR for container registry
   - EKS cluster deployment
   - IAM roles and permissions

6. **DevOps Best Practices**
   - Infrastructure as Code
   - Automation and orchestration
   - Monitoring and logging
   - Security in CI/CD

---

## Support

For issues or questions:

1. Check Jenkins logs: `/var/log/jenkins/jenkins.log`
2. Check pipeline console output in Jenkins UI
3. Verify AWS credentials and permissions
4. Check EKS cluster status
5. Jenkins Documentation: https://www.jenkins.io/doc/
6. Helm Documentation: https://helm.sh/docs/
7. AWS Documentation: https://docs.aws.amazon.com/

---

**Happy Learning! 🚀**
