variable "aws_region" {
    type = string
    default = "us-east-1"
}

variable "project_prefix" {
    type = string
    default = "demo33c"
}

variable "apigw_path1" {}

variable "cognito_user_name" {
    type = string
}

variable "lambda_runtime" {
    type = string
    default = "python3.13"
}

variable "cwlogs_retention_in_days" {
    type = number
}