provider "aws" {
  alias  = "r1"
  region = var.aws_region1
}

provider "aws" {
  alias  = "r2"
  region = var.aws_region2
}
