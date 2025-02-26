terraform {
  backend "s3" {
    region         = "eu-west-3"
    bucket         = "cpa7777"
    key            = "terraform/demo14b.tfstate"
    dynamodb_table = "TerraformLock"
  }
}

provider "aws" {
  region     = var.aws_region
}
