terraform {
  backend "s3" {
    region         = "eu-west-3"
    bucket         = "cpa7777"
    key            = "terraform/demo14.tfstate"
  }
}

provider "aws" {
  region     = var.aws_region
}
