provider "aws" {
  alias   = "acct1"
  region  = var.acct1_region
  profile = var.acct1_profile 
}

provider "aws" {
  alias   = "acct2"
  region  = var.acct2_region
  profile = var.acct2_profile 
}