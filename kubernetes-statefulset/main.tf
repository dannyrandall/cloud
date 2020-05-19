resource "kubernetes_storage_class" "this" {
  metadata {
    name = var.name

    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  storage_provisioner    = var.storage_provisioner
  reclaim_policy         = "Retain"
  allow_volume_expansion = true

  parameters = merge(var.storage_class_parameters, {})
}

resource "kubernetes_stateful_set" "this" {
  metadata {
    name = var.name

    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/version"    = var.image_version
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    service_name = var.name
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.name
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = var.name
          "app.kubernetes.io/version" = var.image_version
        }
      }

      spec {
        dynamic "image_pull_secrets" {
          for_each = length(var.image_pull_secret) > 0 ? [var.image_pull_secret] : []

          content {
            name = image_pull_secrets.value
          }
        }

        container {
          name              = "server"
          image             = "${var.image}:${var.image_version}"
          image_pull_policy = "Always"

          args = var.container_args

          port {
            container_port = var.container_port
          }

          // environment vars
          dynamic "env" {
            for_each = var.container_env

            content {
              name  = env.key
              value = env.value
            }
          }

          // TODO liveness/readiness

          volume_mount {
            name       = "${var.name}-storage"
            mount_path = var.storage_mount_path
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "${var.name}-storage"

        labels = {
          "app.kubernetes.io/name"       = "${var.name}-storage"
          "app.kubernetes.io/managed-by" = "terraform"
        }
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = kubernetes_storage_class.this.metadata.0.name

        resources {
          requests = {
            storage = var.storage_request_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name = var.name

    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 80
      target_port = var.container_port
    }

    selector = {
      "app.kubernetes.io/name" = var.name
    }
  }
}

resource "kubernetes_ingress" "this" {
  // only create the ingress if there is at least one public url
  count = length(var.public_urls) > 0 ? 1 : 0

  metadata {
    name = var.name

    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/managed-by" = "terraform"
    }

    annotations = merge(var.ingress_annotations, {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    })
  }

  spec {
    dynamic "rule" {
      for_each = var.public_urls

      content {
        host = rule.value

        http {
          path {
            backend {
              service_name = kubernetes_service.this.metadata.0.name
              service_port = 80
            }
          }
        }
      }
    }
  }
}
