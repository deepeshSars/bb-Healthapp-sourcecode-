# Jenkins Pipeline Execution and Testing Guide

## Table of Contents
1. [Creating a Pipeline Job](#creating-a-pipeline-job)
2. [Configuring the Pipeline Job](#configuring-the-pipeline-job)
3. [Running the Pipeline](#running-the-pipeline)
4. [Monitoring Pipeline Execution](#monitoring-pipeline-execution)
5. [Verifying Deployment](#verifying-deployment)
6. [Troubleshooting Pipeline Issues](#troubleshooting-pipeline-issues)
7. [Screenshots Checklist](#screenshots-checklist)

---

## Creating a Pipeline Job

### Step 1: Access Jenkins Dashboard

1. Open your browser and navigate to: `http://<jenkins-server-ip>:8080`
2. Login with your admin credentials

**📸 Screenshot Required:** Take a screenshot of the Jenkins dashboard.

### Step 2: Create New Item

1. Click **New Item** on the left sidebar
2. Enter **Item name**: `bbhealthapp-pipeline`
3. Select **Pipeline** as the project type
4. Click **OK**

**📸 Screenshot Required:** Take a screenshot of the "New Item" page with the name and type selected.

---

## Configuring the Pipeline Job

### Step 1: General Configuration

1. In the **General** section:
   - **Description**: Add a description like "CI/CD pipeline for BB Health App - builds, tests, and deploys to EKS"
   - **Discard old builds**: Check this box to save disk space
     - **Max # of builds to keep**: `10`
     - **Max # of builds to keep with artifacts**: `5`

### Step 2: Pipeline Configuration

1. Scroll to the **Pipeline** section
2. **Definition**: Select `Pipeline script from SCM`
3. **SCM**: Select `Git`
4. **Repository URL**: Enter your Git repository URL
   - Example: `https://github.com/your-username/bb-Healthapp-sourcecode.git`
5. **Credentials**: Select your Git credentials (if using private repository)
6. **Branch Specifier**: `*/main` or `*/master` (depending on your branch name)
7. **Script Path**: `Jenkinsfile`
8. **Lightweight checkout**: Check this box for faster checkout

**📸 Screenshot Required:** Take a screenshot of the Pipeline configuration section showing all settings.

### Step 3: Build Triggers (Optional)

1. In the **Build Triggers** section, you can configure:
   - **Poll SCM**: Trigger builds periodically (e.g., `H/5 * * * *` for every 5 minutes)
   - **GitHub hook trigger for GITScm polling**: For GitHub webhooks
   - **Build when a change is pushed to GitHub**: For GitHub integration

### Step 4: Save Configuration

1. Click **Save** or **Apply** to save the job configuration

---

## Running the Pipeline

### Option 1: Manual Build

1. Navigate to the pipeline job: `bbhealthapp-pipeline`
2. Click **Build Now** on the left sidebar
3. A new build will start and appear in the **Build History**

**📸 Screenshot Required:** Take a screenshot of the job page showing the "Build Now" button.

### Option 2: Automatic Build (if triggers configured)

- If you configured GitHub webhooks or polling, the pipeline will trigger automatically on code changes

---

## Monitoring Pipeline Execution

### Step 1: View Build Progress

1. Click on the running build number in **Build History**
2. You will see the build progress in real-time
3. The pipeline stages will be displayed with their status

**📸 Screenshot Required:** Take a screenshot of the pipeline execution dashboard showing all stages.

### Step 2: Check Console Output

1. Click **Console Output** to view detailed logs
2. Monitor each stage's execution:
   - **Checkout**: Git repository checkout
   - **Build Frontend**: npm install and build
   - **Build Backend Services**: Maven builds (parallel execution)
   - **Configure AWS Credentials**: AWS authentication
   - **Build Docker Images**: Docker image creation
   - **Push Images to ECR**: Push to Amazon ECR
   - **Deploy to EKS**: Kubernetes deployment
   - **Verify Deployment**: Pod and service verification
   - **Clean Up**: Docker cleanup

**📸 Screenshot Required:** Take a screenshot of the console output showing successful completion.

### Step 3: Stage View

1. Navigate back to the job page
2. Click **Stage View** to see a visual representation of the pipeline stages
3. Each stage shows:
   - Duration
   - Status (passed/failed)
   - Execution time

**📸 Screenshot Required:** Take a screenshot of the Stage View showing all stages completed successfully.

---

## Pipeline Stages Detailed View

### Stage 1: Checkout

**Purpose**: Checkout source code from Git repository

**Expected Output**:
```
=== Checkout Stage ===
Checking out source code from repository
Git Commit: abc1234
Build Number: 1
Image Tag: 1-abc1234
```

**Time**: ~30 seconds

### Stage 2: Build Frontend

**Purpose**: Install dependencies and build React frontend

**Expected Output**:
```
=== Build Frontend Stage ===
Installing frontend dependencies...
Building frontend application...
Frontend build completed successfully
```

**Time**: ~3-5 minutes

### Stage 3: Build Backend Services

**Purpose**: Build all three Java microservices in parallel

**Expected Output**:
```
=== Build Master Service ===
Building master service with Maven...
Master service build completed

=== Build Register Service ===
Building register service with Maven...
Register service build completed

=== Build Document Service ===
Building document service with Maven...
Document service build completed
```

**Time**: ~5-10 minutes (parallel execution)

### Stage 4: Configure AWS Credentials

**Purpose**: Authenticate with AWS and login to ECR

**Expected Output**:
```
=== Configure AWS Credentials ===
AWS credentials validated successfully
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/username"
}
ECR login successful
Login Succeeded
```

**Time**: ~30 seconds

### Stage 5: Build Docker Images

**Purpose**: Build Docker images for all services

**Expected Output**:
```
=== Build Docker Images Stage ===
AWS Account ID: 123456789012
Building frontend Docker image...
Frontend Docker image built successfully
Building master service Docker image...
Master service Docker image built successfully
Building register service Docker image...
Register service Docker image built successfully
Building document service Docker image...
Document service Docker image built successfully
```

**Time**: ~5-8 minutes

### Stage 6: Push Images to ECR

**Purpose**: Push Docker images to Amazon ECR

**Expected Output**:
```
=== Push Images to ECR Stage ===
Pushing frontend image to ECR...
Frontend image pushed successfully
Pushing master service image to ECR...
Master service image pushed successfully
Pushing register service image to ECR...
Register service image pushed successfully
Pushing document service image to ECR...
Document service image pushed successfully
All images pushed to ECR successfully
```

**Time**: ~3-5 minutes (depends on image size and network)

**📸 Screenshot Required:** Take a screenshot of the ECR repository showing the pushed images.

### Stage 7: Deploy to EKS

**Purpose**: Update Kubernetes deployments with new images

**Expected Output**:
```
=== Deploy to EKS Stage ===
kubectl configured for EKS cluster
Updating Kubernetes deployments...
Deployments updated successfully
Waiting for deployments to roll out...
deployment.apps/master-service successfully rolled out
deployment.apps/register-service successfully rolled out
deployment.apps/document-service successfully rolled out
deployment.apps/frontend successfully rolled out
All deployments rolled out successfully
```

**Time**: ~2-3 minutes

### Stage 8: Verify Deployment

**Purpose**: Verify pods and services are running correctly

**Expected Output**:
```
=== Verify Deployment Stage ===
NAME                                   READY   STATUS    RESTARTS   AGE
master-service-7d8f9b2c-1a2b3          1/1     Running   0          2m
register-service-8e0g1c3d-4e5f6        1/1     Running   0          2m
document-service-9f1h2d4e-6g7h8        1/1     Running   0          2m
frontend-0g2i3e5f-8h9i0               1/1     Running   0          2m

NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
master-service          ClusterIP      10.100.200.10    <none>        8080/TCP       10d
register-service        ClusterIP      10.100.200.11    <none>        8080/TCP       10d
document-service        ClusterIP      10.100.200.12    <none>        8080/TCP       10d
frontend                LoadBalancer   10.100.200.13    a1b2c3d4...   80:31234/TCP   10d

Deployment verification completed
```

**Time**: ~30 seconds

**📸 Screenshot Required:** Take a screenshot of the EKS pods and services.

### Stage 9: Clean Up

**Purpose**: Clean up local Docker images to save disk space

**Expected Output**:
```
=== Clean Up Stage ===
Cleaning up local Docker images...
Deleted: sha256:abc123...
Deleted: sha256:def456...
Cleanup completed
```

**Time**: ~1 minute

---

## Verifying Deployment

### Step 1: Check ECR Repositories

1. Log in to AWS Console
2. Navigate to **Elastic Container Registry (ECR)**
3. Check each repository:
   - `bbhealthapp-dev-master-service`
   - `bbhealthapp-dev-register-service`
   - `bbhealthapp-dev-document-service`
   - `bbhealthapp-dev-frontend`
4. Verify new images are present with the build tag

**📸 Screenshot Required:** Take a screenshot of ECR repositories showing the pushed images.

### Step 2: Check EKS Cluster

1. Log in to AWS Console
2. Navigate to **EKS** → **bbhealthapp-eks**
3. Click **Compute** → **Node groups**
4. Verify nodes are healthy

### Step 3: Check Kubernetes Pods

```bash
# Get all pods in the namespace
kubectl get pods -n bbhealthapp

# Expected output: All pods should be in Running state
```

**📸 Screenshot Required:** Take a screenshot of the pods running in EKS.

### Step 4: Check Services

```bash
# Get all services
kubectl get services -n bbhealthapp

# Expected output: All services should be listed
```

### Step 5: Access the Application

1. Get the LoadBalancer external IP:
   ```bash
   kubectl get service frontend -n bbhealthapp
   ```
2. Open the external IP in your browser
3. Verify the application is accessible

### Step 6: Check Pod Logs

```bash
# Check master service logs
kubectl logs -l app=master-service -n bbhealthapp

# Check register service logs
kubectl logs -l app=register-service -n bbhealthapp

# Check document service logs
kubectl logs -l app=document-service -n bbhealthapp

# Check frontend logs
kubectl logs -l app=frontend -n bbhealthapp
```

---

## Troubleshooting Pipeline Issues

### Issue: Checkout Stage Fails

**Symptoms**: Git checkout fails with authentication error

**Solutions**:
1. Verify Git credentials are configured in Jenkins
2. Check repository URL is correct
3. Verify branch name matches
4. Check network connectivity to Git repository

### Issue: Build Frontend Fails

**Symptoms**: npm install or build fails

**Solutions**:
1. Check Node.js version (should be 18 or higher)
2. Verify package.json is valid
3. Check for missing dependencies
4. Review console output for specific error messages

### Issue: Build Backend Services Fails

**Symptoms**: Maven build fails

**Solutions**:
1. Check Java version (should be 11 or higher)
2. Verify pom.xml files are valid
3. Check Maven dependencies
4. Review console output for specific error messages
5. Ensure sufficient memory is available for Maven builds

### Issue: AWS Credentials Fail

**Symptoms**: AWS authentication fails

**Solutions**:
1. Verify AWS credentials are correctly configured in Jenkins
2. Check IAM user has necessary permissions (ECR, EKS)
3. Verify AWS region is correct (ap-south-1)
4. Test credentials manually with `aws sts get-caller-identity`

### Issue: Docker Build Fails

**Symptoms**: Docker build fails

**Solutions**:
1. Verify Docker is installed and running
2. Check Docker daemon is accessible by Jenkins user
3. Ensure sufficient disk space
4. Verify Dockerfile syntax is correct
5. Check base images are accessible

### Issue: ECR Push Fails

**Symptoms**: Push to ECR fails

**Solutions**:
1. Verify ECR login was successful
2. Check ECR repository exists
3. Verify IAM user has ECR push permissions
4. Check network connectivity to ECR
5. Verify image tags are correct

### Issue: EKS Deployment Fails

**Symptoms**: Kubernetes deployment fails

**Solutions**:
1. Verify kubectl is configured for correct cluster
2. Check kubeconfig has correct permissions
3. Verify namespace exists (bbhealthapp)
4. Check deployment manifests are valid
5. Review pod logs for application errors
6. Verify image tags match what was pushed to ECR

### Issue: Pods Not Running

**Symptoms**: Pods are in CrashLoopBackOff or Pending state

**Solutions**:
1. Check pod events: `kubectl describe pod <pod-name> -n bbhealthapp`
2. Review pod logs: `kubectl logs <pod-name> -n bbhealthapp`
3. Verify image pull works (ECR access)
4. Check resource limits and requests
5. Verify application configuration (ConfigMaps, Secrets)

---

## Screenshots Checklist

### Pipeline Job Setup

- [ ] **Jenkins Dashboard** - Main dashboard after login
- [ ] **New Item Page** - Creating new pipeline job
- [ ] **Pipeline Configuration** - Complete job configuration
- [ ] **Job Page** - Job page with Build Now button

### Pipeline Execution

- [ ] **Build History** - Build showing in progress
- [ ] **Pipeline Execution Dashboard** - All stages with status
- [ ] **Console Output** - Full console output of successful build
- [ ] **Stage View** - Visual representation of all stages
- [ ] **Build Success Badge** - Green checkmark indicating success

### Deployment Verification

- [ ] **ECR Repositories** - Images pushed to ECR with tags
- [ ] **EKS Cluster** - Cluster overview showing healthy nodes
- [ ] **Kubernetes Pods** - All pods in Running state
- [ ] **Kubernetes Services** - All services listed
- [ ] **Application Access** - Browser showing the application

### Failure Screenshots (if applicable)

- [ ] **Error Logs** - Console output showing error
- [ ] **Failed Stage** - Stage that failed with error message
- [ ] **Pod Events** - kubectl describe pod output

---

## Performance Metrics

### Expected Pipeline Duration

- **Total Time**: ~20-30 minutes
- **Checkout**: ~30 seconds
- **Build Frontend**: ~3-5 minutes
- **Build Backend**: ~5-10 minutes (parallel)
- **AWS Configuration**: ~30 seconds
- **Docker Build**: ~5-8 minutes
- **ECR Push**: ~3-5 minutes
- **EKS Deploy**: ~2-3 minutes
- **Verification**: ~30 seconds
- **Cleanup**: ~1 minute

### Optimization Tips

1. **Use Docker Layer Caching**: Speed up Docker builds
2. **Parallel Builds**: Backend services already build in parallel
3. **Incremental Builds**: Skip unchanged services
4. **Use Build Agents**: Distribute builds across multiple agents
5. **Artifact Caching**: Cache Maven dependencies and npm packages

---

## Post-Deployment Verification Checklist

- [ ] All pods are in Running state
- [ ] All services are accessible
- [ ] Application loads in browser
- [ ] Frontend can connect to backend services
- [ ] No errors in pod logs
- [ ] Images are visible in ECR
- [ ] Old images are cleaned up (if configured)
- [ ] Ingress is working (if configured)
- [ ] SSL/TLS is working (if configured)

---

## Rollback Procedure

If deployment fails or causes issues:

### Option 1: Manual Rollback

```bash
# Rollback to previous image tag
kubectl rollout undo deployment/master-service -n bbhealthapp
kubectl rollout undo deployment/register-service -n bbhealthapp
kubectl rollout undo deployment/document-service -n bbhealthapp
kubectl rollout undo deployment/frontend -n bbhealthapp
```

### Option 2: Re-run Previous Build

1. Navigate to Jenkins job
2. Click **Build History**
3. Select previous successful build
4. Click **Rebuild**

### Option 3: Manually Set Previous Image

```bash
# Set specific image tag
kubectl set image deployment/master-service \
  master-service=<account-id>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-master-service:<previous-tag> \
  -n bbhealthapp
```

---

## Next Steps

After successful pipeline execution:

1. **Configure Webhooks**: Set up GitHub webhooks for automatic builds
2. **Add Notifications**: Configure email or Slack notifications
3. **Add Tests**: Integrate automated tests in the pipeline
4. **Add Code Quality**: Integrate SonarQube or similar tools
5. **Add Security Scanning**: Integrate Trivy or similar security scanners
6. **Set Up Monitoring**: Configure Prometheus/Grafana for monitoring

---

## Additional Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [AWS ECR Best Practices](https://docs.aws.amazon.com/AmazonECR/latest/userguide/best-practices.html)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
