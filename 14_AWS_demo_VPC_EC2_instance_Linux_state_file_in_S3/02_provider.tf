terraform {
  backend "s3" {
    region = "eu-west-3"
    bucket = "terraform-state-cpa-mb1"
    key    = "terraform/demo14.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}
