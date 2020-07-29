data "digitalocean_domain" "personal" {
  name = "danielrandall.dev"
}

//resource "digitalocean_certificate" "cert" {
//  name    = "cert-personal"
//  type    = "lets_encrypt"
//  //domains = ["*.${data.digitalocean_domain.personal.name}"]
//  //domains = ["${data.digitalocean_domain.personal.name}"]
//}
