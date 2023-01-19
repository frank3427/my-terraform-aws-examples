terraform {
  backend "s3" {
    bucket = "cpabucket"
    key    = "terraform/demo14.tfstate"
    region = "eu-west-3"
  }
}

provider "aws" {
  region     = var.aws_region
}
