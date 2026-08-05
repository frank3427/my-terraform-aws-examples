terraform {
  required_version = ">= 1.4"
}

provider "aws" {
  region = var.aws_region
}

provider "awscc" {
  region = var.aws_region
}
