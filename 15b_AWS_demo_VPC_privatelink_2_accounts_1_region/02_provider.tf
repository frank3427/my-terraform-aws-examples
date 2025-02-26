provider "aws" {
  alias   = "acct1"
  region  = var.aws_region
  profile = var.acct1_profile 
}

provider "aws" {
  alias   = "acct2"
  region  = var.aws_region
  profile = var.acct2_profile 
}