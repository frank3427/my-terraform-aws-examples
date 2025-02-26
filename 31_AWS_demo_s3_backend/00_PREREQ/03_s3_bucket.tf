resource aws_s3_bucket demo31 {
  bucket = var.s3_bucket
  # object_lock_enabled = true
  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}

resource aws_s3_bucket_versioning demo31 {
  bucket = aws_s3_bucket.demo31.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource aws_s3_bucket_server_side_encryption_configuration demo31 {
  bucket = aws_s3_bucket.demo31.id
  rule {
      apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
      }
  }
}

# resource aws_s3_bucket_object_lock_configuration demo31 {
#   bucket = aws_s3_bucket.demo31.id

#   rule {
#     default_retention {
#       mode = "COMPLIANCE"
#       days = 1
#     }
#   }
# }