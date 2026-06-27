variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "dynamodb_tab" {
  type        = string
  description = "DynamoDB table name for Terraform state locking"
}
variable "s3_bucket" {
  type        = string
  description = "S3 bucket name"
}
