variable "nginx_ingress_controller_version" {
  description = "The version of Nginx Ingress Controller to use. See https://github.com/kubernetes/ingress-nginx/releases for available versions"
  type        = string
  default     = "0.29.0"
}

variable "lb_annotations" {
  description = "Annotations to add to the kubernetes load balancer resource."
  type        = map(string)
  default     = {}
}
