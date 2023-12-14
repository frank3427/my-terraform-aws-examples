provider "awscc" {
  region     = var.aws_region
}

# aws provider also requires at this point as some resources are missing in awscc
provider "aws" {
  region     = var.aws_region
}