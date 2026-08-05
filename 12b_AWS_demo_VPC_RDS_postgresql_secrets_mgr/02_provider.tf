terraform {
  required_version = ">= 1.4"
}

provider "aws" {
  region = var.aws_region
}
