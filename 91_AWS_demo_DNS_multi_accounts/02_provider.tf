provider "aws" {
  alias   = "acct0"
  region  = var.aws_region
  profile = var.account0_profile 
}

provider "aws" {
  alias   = "acct1"
  region  = var.aws_region
  profile = var.account1_profile 
}

provider "aws" {
  alias   = "acct2"
  region  = var.aws_region
  profile = var.account2_profile 
}