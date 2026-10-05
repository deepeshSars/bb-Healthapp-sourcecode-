# IAM Role for Master Service (Least Privilege)
resource "aws_iam_role" "master_service" {
  name = "${local.name_prefix}-master-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Service = "master-service"
  })
}

resource "aws_iam_role_policy" "master_service_policy" {
  name = "${local.name_prefix}-master-service-policy"
  role = aws_iam_role.master_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = aws_ecr_repository.master_service.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Role for Register Service (Least Privilege)
resource "aws_iam_role" "register_service" {
  name = "${local.name_prefix}-register-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Service = "register-service"
  })
}

resource "aws_iam_role_policy" "register_service_policy" {
  name = "${local.name_prefix}-register-service-policy"
  role = aws_iam_role.register_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = aws_ecr_repository.register_service.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Role for Document Service (Least Privilege)
resource "aws_iam_role" "document_service" {
  name = "${local.name_prefix}-document-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Service = "document-service"
  })
}

resource "aws_iam_role_policy" "document_service_policy" {
  name = "${local.name_prefix}-document-service-policy"
  role = aws_iam_role.document_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = aws_ecr_repository.document_service.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.document_uploads.arn}/*"
      }
    ]
  })
}

# IAM Role for Frontend (Least Privilege)
resource "aws_iam_role" "frontend_service" {
  name = "${local.name_prefix}-frontend-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Service = "frontend"
  })
}

resource "aws_iam_role_policy" "frontend_service_policy" {
  name = "${local.name_prefix}-frontend-service-policy"
  role = aws_iam_role.frontend_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = aws_ecr_repository.frontend.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Instance Profiles for EC2
resource "aws_iam_instance_profile" "master_service" {
  name = "${local.name_prefix}-master-service-profile"
  role = aws_iam_role.master_service.name
}

resource "aws_iam_instance_profile" "register_service" {
  name = "${local.name_prefix}-register-service-profile"
  role = aws_iam_role.register_service.name
}

resource "aws_iam_instance_profile" "document_service" {
  name = "${local.name_prefix}-document-service-profile"
  role = aws_iam_role.document_service.name
}

resource "aws_iam_instance_profile" "frontend_service" {
  name = "${local.name_prefix}-frontend-service-profile"
  role = aws_iam_role.frontend_service.name
}
