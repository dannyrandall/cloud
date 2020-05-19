resource "digitalocean_kubernetes_cluster" "default_prd" {
  name     = "k8s-default-cluster-prd"
  region   = "sfo2"
  version  = "1.17.5-do.0"
  vpc_uuid = digitalocean_vpc.default_prd.id

  node_pool {
    name       = "k8s-default-pool-prd"
    size       = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }
}

provider "kubernetes" {
  load_config_file = false
  host             = digitalocean_kubernetes_cluster.default_prd.endpoint
  token            = digitalocean_kubernetes_cluster.default_prd.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.default_prd.kube_config[0].cluster_ca_certificate
  )
}

module "nginx_ingress_controller" {
  source = "../kubernetes-nginx-ingress-controller"

  lb_annotations = {
    "service.beta.kubernetes.io/do-loadbalancer-protocol"               = "tcp"
    "service.beta.kubernetes.io/do-loadbalancer-algorithm"              = "round_robin"
    "service.beta.kubernetes.io/do-loadbalancer-tls-ports"              = "443"
    "service.beta.kubernetes.io/do-loadbalancer-certificate-id"         = digitalocean_certificate.cert.id
    "service.beta.kubernetes.io/do-loadbalancer-redirect-http-to-https" = "true"
    "service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol"  = "true"
  }
}
