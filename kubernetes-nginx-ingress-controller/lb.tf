resource "kubernetes_service" "lb" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.nginx.metadata.0.name

    labels = {
      "app.kubernetes.io/name"       = local.name
      "app.kubernetes.io/part-of"    = kubernetes_namespace.nginx.metadata.0.name
      "app.kubernetes.io/managed-by" = "terraform"
    }

    annotations = merge(var.lb_annotations, {})
  }

  spec {
    type = "LoadBalancer"
    selector = {
      "app.kubernetes.io/name"    = local.name
      "app.kubernetes.io/part-of" = kubernetes_namespace.nginx.metadata.0.name
    }

    external_traffic_policy = "Local"

    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }

    port {
      name        = "https"
      port        = 443
      target_port = "https"
    }
  }
}
