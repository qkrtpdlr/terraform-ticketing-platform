# modules/storage/main.tf

variable "project_name" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string); default = {} }

# S3 Bucket (티켓 이미지, 정적 파일)
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-bucket"
  
  tags = merge(
    { Name = "${var.project_name}-${var.environment}-bucket" },
    var.tags
  )
}

# 버전 관리 활성화
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 암호화 활성화
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public Access 차단
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" { value = aws_s3_bucket.main.id }
output "bucket_arn" { value = aws_s3_bucket.main.arn }
