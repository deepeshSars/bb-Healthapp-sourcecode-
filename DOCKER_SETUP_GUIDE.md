# Docker Setup Guide for BB Health App

## Dockerfiles Created

### 1. Document Service Dockerfile
Location: `bbhealthapp-backend/bbhealthapp-api-document/Dockerfile`

### 2. Master Service Dockerfile
Location: `bbhealthapp-backend/bbhealthapp-api-master/Dockerfile`

### 3. Register Service Dockerfile
Location: `bbhealthapp-backend/bbhealthapp-api-register/Dockerfile`

### 4. Frontend Dockerfile
Location: `bbhealthapp-frontend/Dockerfile`

## Building Docker Images Locally

### Document Service
```bash
cd bbhealthapp-backend/bbhealthapp-api-document
docker build -t bbhealthapp-document-service:latest .
```

### Master Service
```bash
cd bbhealthapp-backend/bbhealthapp-api-master
docker build -t bbhealthapp-master-service:latest .
```

### Register Service
```bash
cd bbhealthapp-backend/bbhealthapp-api-register
docker build -t bbhealthapp-register-service:latest .
```

### Frontend
```bash
cd bbhealthapp-frontend
docker build -t bbhealthapp-frontend:latest .
```

## Testing Docker Images Locally

### Run Document Service
```bash
docker run -d -p 8081:8080 --name document-service bbhealthapp-document-service:latest
docker logs document-service
```

### Run Master Service
```bash
docker run -d -p 8082:8080 --name master-service bbhealthapp-master-service:latest
docker logs master-service
```

### Run Register Service
```bash
docker run -d -p 8083:8080 --name register-service bbhealthapp-register-service:latest
docker logs register-service
```

### Run Frontend
```bash
docker run -d -p 80:80 --name frontend bbhealthapp-frontend:latest
docker logs frontend
```

### Stop Containers
```bash
docker stop document-service master-service register-service frontend
docker rm document-service master-service register-service frontend
```

## ECR Setup

### 1. Login to ECR
```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
```

### 2. Get ECR Repository URLs
The Terraform configuration will create these repositories:
- `bbhealthapp-dev-master-service`
- `bbhealthapp-dev-register-service`
- `bbhealthapp-dev-document-service`
- `bbhealthapp-dev-frontend`

Your ECR registry URL will be: `<YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com`

## Push Images to ECR

### Document Service
```bash
docker tag bbhealthapp-document-service:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-document-service:latest
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-document-service:latest
```

### Master Service
```bash
docker tag bbhealthapp-master-service:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-master-service:latest
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-master-service:latest
```

### Register Service
```bash
docker tag bbhealthapp-register-service:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-register-service:latest
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-register-service:latest
```

### Frontend
```bash
docker tag bbhealthapp-frontend:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-frontend:latest
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-frontend:latest
```

## Clean Up Local Docker Images
```bash
docker system prune -f
```

## Notes

1. **Build Time**: Maven builds can take 5-10 minutes depending on your internet speed and dependencies
2. **Java Version**: All backend services use Java 11 (Eclipse Temurin)
3. **Frontend**: Uses Node 16 and nginx for serving static files
4. **Ports**: Different services are mapped to different ports to avoid conflicts during local testing
5. **ECR**: Make sure you have AWS credentials configured before pushing to ECR

## Verification Steps

1. Build each image locally
2. Run each container and check logs with `docker logs <container-name>`
3. Verify services are accessible on their respective ports
4. Stop containers after testing
5. Push images to ECR
6. Verify images appear in AWS ECR console
7. Clean up local images with `docker system prune -f`
