# S3 Bucket for Document Uploads
resource "aws_s3_bucket" "document_uploads" {
  bucket = "${local.name_prefix}-document-uploads"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-document-uploads"
  })
}

resource "aws_s3_bucket_versioning" "document_uploads" {
  bucket = aws_s3_bucket.document_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "document_uploads" {
  bucket = aws_s3_bucket.document_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "document_uploads" {
  bucket = aws_s3_bucket.document_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
