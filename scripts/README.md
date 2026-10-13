# Jenkins Setup Helper Scripts

This directory contains helper scripts to automate the Jenkins CI/CD pipeline setup process.

## Overview

These scripts help you:
- Check system prerequisites
- Install Jenkins on Ubuntu/Debian or CentOS/RHEL
- Install required Jenkins plugins
- Configure AWS and other credentials
- Perform complete end-to-end setup

## Scripts

### 1. check-prerequisites.sh

Verifies that all required tools are installed and configured before installing Jenkins.

**What it checks:**
- Java 11+ (required for Jenkins)
- Docker (for building images)
- kubectl (for Kubernetes deployments)
- AWS CLI (for ECR and EKS access)
- Git (for repository checkout)
- Maven (optional, used inside Docker)
- Node.js (optional, used inside Docker)
- Disk space and memory
- Network connectivity

**Usage:**
```bash
bash scripts/check-prerequisites.sh
```

**Requirements:** None (run as regular user)

---

### 2. install-jenkins-ubuntu.sh

Installs Jenkins on Ubuntu/Debian systems.

**What it does:**
- Updates system packages
- Installs Java 11
- Adds Jenkins repository
- Installs Jenkins
- Starts and enables Jenkins service
- Displays initial admin password
- Configures firewall (if UFW is installed)
- Adds jenkins user to docker group (if Docker is installed)

**Usage:**
```bash
sudo bash scripts/install-jenkins-ubuntu.sh
```

**Requirements:** Run as root or with sudo

---

### 3. install-jenkins-centos.sh

Installs Jenkins on CentOS/RHEL systems.

**What it does:**
- Updates system packages
- Installs Java 11
- Adds Jenkins repository
- Installs Jenkins
- Starts and enables Jenkins service
- Displays initial admin password
- Configures firewall (if firewalld is installed)
- Configures SELinux (if enabled)
- Adds jenkins user to docker group (if Docker is installed)

**Usage:**
```bash
sudo bash scripts/install-jenkins-centos.sh
```

**Requirements:** Run as root or with sudo

---

### 4. install-jenkins-plugins.sh

Installs required Jenkins plugins using the Jenkins CLI.

**What it installs:**
- pipeline
- git
- docker-workflow
- aws-credentials
- kubernetes-cli
- credentials-binding
- ws-cleanup
- git-parameter
- pipeline-stage-view
- timestamper
- workflow-aggregator
- ssh-slaves
- matrix-auth
- jdk-tool
- command-launcher

**Usage:**
```bash
# Set environment variables
export JENKINS_URL="http://localhost:8080"
export JENKINS_USER="admin"
export JENKINS_PASSWORD="your-password"

# Run the script
bash scripts/install-jenkins-plugins.sh
```

**Requirements:**
- Jenkins must be running
- Jenkins admin credentials
- Java (for Jenkins CLI)

---

### 5. setup-jenkins-credentials.sh

Interactive script to configure credentials in Jenkins.

**What it can configure:**
- AWS Credentials (for ECR and EKS access)
- Git Credentials (for private repositories)
- Docker Hub Credentials (for pushing to Docker Hub)
- Test AWS credentials locally

**Usage:**
```bash
# Set environment variables
export JENKINS_URL="http://localhost:8080"
export JENKINS_USER="admin"
export JENKINS_PASSWORD="your-password"

# Run the script
bash scripts/setup-jenkins-credentials.sh
```

**Requirements:**
- Jenkins must be running
- Jenkins admin credentials
- Java (for Jenkins CLI)

---

### 6. setup-jenkins-complete.sh

Master script that orchestrates the complete Jenkins setup process.

**What it does:**
1. Checks prerequisites
2. Installs Jenkins (detects OS automatically)
3. Waits for Jenkins to start
4. Displays initial admin password
5. Guides you through initial Jenkins setup
6. Installs additional plugins
7. Sets up credentials
8. Configures Docker access
9. Provides summary and next steps

**Usage:**
```bash
sudo bash scripts/setup-jenkins-complete.sh
```

**Requirements:** Run as root or with sudo

---

## Quick Start

### Option 1: Complete Automated Setup

Run the master script for hands-off setup:

```bash
sudo bash scripts/setup-jenkins-complete.sh
```

This will guide you through the entire setup process.

### Option 2: Step-by-Step Setup

If you prefer manual control over each step:

```bash
# Step 1: Check prerequisites
bash scripts/check-prerequisites.sh

# Step 2: Install Jenkins (choose based on your OS)
sudo bash scripts/install-jenkins-ubuntu.sh    # For Ubuntu/Debian
# OR
sudo bash scripts/install-jenkins-centos.sh   # For CentOS/RHEL

# Step 3: Complete initial Jenkins setup in browser
# Open: http://localhost:8080
# Use the initial admin password displayed by the installation script

# Step 4: Install additional plugins
export JENKINS_URL="http://localhost:8080"
export JENKINS_USER="admin"
export JENKINS_PASSWORD="your-admin-password"
bash scripts/install-jenkins-plugins.sh

# Step 5: Configure credentials
bash scripts/setup-jenkins-credentials.sh
```

---

## Environment Variables

The following environment variables can be set for the scripts:

### For Plugin Installation and Credentials Setup

- `JENKINS_URL`: Jenkins server URL (default: `http://localhost:8080`)
- `JENKINS_USER`: Jenkins username (default: `admin`)
- `JENKINS_PASSWORD`: Jenkins password (required)

**Example:**
```bash
export JENKINS_URL="http://192.168.1.100:8080"
export JENKINS_USER="admin"
export JENKINS_PASSWORD="secret123"
```

---

## Troubleshooting

### Script Permission Denied

If you get permission denied errors, make the script executable:

```bash
chmod +x scripts/script-name.sh
```

### Jenkins CLI Connection Failed

Ensure Jenkins is running and accessible:

```bash
# Check Jenkins status
sudo systemctl status jenkins

# Check if port 8080 is open
curl http://localhost:8080
```

### Docker Permission Denied

Add jenkins user to docker group:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### AWS Credentials Not Working

Test AWS credentials locally:

```bash
aws sts get-caller-identity
```

If this fails, configure AWS CLI:

```bash
aws configure
```

---

## Security Best Practices

1. **Never hardcode credentials** in scripts or Jenkinsfile
2. **Use Jenkins credentials store** for sensitive data
3. **Rotate credentials regularly**
4. **Use least privilege IAM policies** for AWS credentials
5. **Enable Jenkins security** with proper authentication
6. **Keep Jenkins and plugins updated**
7. **Review logs regularly** for suspicious activity

---

## Post-Setup Steps

After completing the Jenkins setup:

1. **Create Pipeline Job**
   - Navigate to Jenkins dashboard
   - Click "New Item"
   - Name: `bbhealthapp-pipeline`
   - Type: Pipeline
   - Configure with your Git repository and Jenkinsfile

2. **Configure Webhooks (Optional)**
   - Set up GitHub webhooks for automatic builds
   - Jenkins will trigger on code changes

3. **Add Notifications (Optional)**
   - Configure email or Slack notifications
   - Get notified on build success/failure

4. **Run the Pipeline**
   - Click "Build Now"
   - Monitor execution
   - Verify deployment to EKS

For detailed instructions, refer to:
- [JENKINS_SETUP_GUIDE.md](../JENKINS_SETUP_GUIDE.md)
- [PIPELINE_EXECUTION_GUIDE.md](../PIPELINE_EXECUTION_GUIDE.md)

---

## Additional Resources

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/)
