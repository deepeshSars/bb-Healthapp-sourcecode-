# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

# EKS Outputs
output "eks_cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_node_group_public_id" {
  description = "ID of the public node group"
  value       = aws_eks_node_group.public.id
}

output "eks_node_group_private_id" {
  description = "ID of the private node group"
  value       = aws_eks_node_group.private.id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# ECR Outputs
output "ecr_master_service_url" {
  description = "URL of the master service ECR repository"
  value       = aws_ecr_repository.master_service.repository_url
}

output "ecr_register_service_url" {
  description = "URL of the register service ECR repository"
  value       = aws_ecr_repository.register_service.repository_url
}

output "ecr_document_service_url" {
  description = "URL of the document service ECR repository"
  value       = aws_ecr_repository.document_service.repository_url
}

output "ecr_frontend_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

# IAM Role Outputs
output "iam_master_service_role_arn" {
  description = "ARN of the master service IAM role"
  value       = aws_iam_role.master_service.arn
}

output "iam_register_service_role_arn" {
  description = "ARN of the register service IAM role"
  value       = aws_iam_role.register_service.arn
}

output "iam_document_service_role_arn" {
  description = "ARN of the document service IAM role"
  value       = aws_iam_role.document_service.arn
}

output "iam_frontend_service_role_arn" {
  description = "ARN of the frontend service IAM role"
  value       = aws_iam_role.frontend_service.arn
}

# S3 Outputs
output "s3_document_uploads_bucket" {
  description = "Name of the document uploads S3 bucket"
  value       = aws_s3_bucket.document_uploads.id
}

output "s3_document_uploads_arn" {
  description = "ARN of the document uploads S3 bucket"
  value       = aws_s3_bucket.document_uploads.arn
}
