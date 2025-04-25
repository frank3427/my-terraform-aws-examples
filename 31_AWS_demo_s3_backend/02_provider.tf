provider "aws" {
  region     = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "demo31-tf-state-cpauliat"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "demo31_tf_state"
  }
}