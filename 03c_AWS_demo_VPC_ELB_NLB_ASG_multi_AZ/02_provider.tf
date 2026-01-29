provider "aws" {
  region     = var.aws_region

 # default tags are optional
  default_tags {
    tags = {
      Management = "Terraform",
      Project    = "demo03c"
    }
  }
}
