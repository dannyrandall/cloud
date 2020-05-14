variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

terraform {
  backend "s3" {
    bucket                      = "terraform-state-storage"
    endpoint                    = "sfo2.digitaloceanspaces.com"
    region                      = "us-west-1"
    key                         = "terraform.tfstate"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_get_ec2_platforms      = true
    skip_metadata_api_check     = true
  }
}
