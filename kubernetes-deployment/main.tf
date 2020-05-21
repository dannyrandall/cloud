resource "kubernetes_service_account" "this" {
  metadata {
    name = var.name

    annotations = {}

    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_deployment" "this" {
  metadata {
    name = var.name

    labels = {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/version"    = var.image_version
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = 1

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
        service_account_name = kubernetes_service_account.this.metadata.0.name

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

          // Volume mounts
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.this.default_secret_name
            read_only  = true
          }

          // container is killed it if fails this check
          dynamic "liveness_probe" {
            for_each = var.health_check ? [1] : []

            content {
              http_get {
                port = var.container_port
                path = "/healthz"
              }

              initial_delay_seconds = 60
              period_seconds        = 60
              timeout_seconds       = 3
            }
          }

          // container is isolated from new traffic if fails this check
          dynamic "readiness_probe" {
            for_each = var.health_check ? [1] : []

            content {
              http_get {
                port = var.container_port
                path = "/healthz"
              }

              initial_delay_seconds = 30
              period_seconds        = 30
              timeout_seconds       = 3
            }
          }
        }

        volume {
          name = kubernetes_service_account.this.default_secret_name

          secret {
            secret_name = kubernetes_service_account.this.default_secret_name
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "10m"
  }
}

// let everyone get to this service at one IP
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
    tls {
      secret_name = "star-av-byu-edu"
      hosts       = var.public_urls
    }

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

