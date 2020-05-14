resource "digitalocean_vpc" "default_prd" {
  name        = "vpc-default-prd"
  description = "default production vpc"
  region      = "sfo2"
  ip_range    = "10.0.0.0/22"
}
