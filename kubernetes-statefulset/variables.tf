variable "name" {
  description = "The name of the service. Must be unique across the cluster."
  type        = string
}

variable "image" {
  description = "The container image url/name"
  type        = string
}

variable "image_version" {
  description = "The version of the image to use"
  type        = string
}

variable "container_port" {
  description = "Port of the container to expose"
  type        = number
}

variable "repo_url" {
  description = "The URL of the service's source code"
  type        = string
}

variable "storage_mount_path" {
  description = ""
  type        = string
}

variable "storage_request_size" {
  description = "Amount of storage this service needs. Ex: '10Gi' for 10 gigabytes, '256Mi' for 256 megabytes."
  type        = string
}

variable "image_pull_secret" {
  description = "The name of the k8s secret with docker credentials needed to pull the image. See https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ for more details"
  type        = string
  default     = ""
}

variable "container_env" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "container_args" {
  description = "Args to run the container with"
  type        = list(string)
  default     = []
}

variable "public_urls" {
  description = "The publicly exposed URLs of the service"
  type        = list(string)
  default     = []
}

variable "ingress_annotations" {
  description = "Annotations to add to the ingress resource. Annotations kubernetes.io/ingress.class, nginx.ingress.kubernetes.io/ssl-redirect, nginx.ingress.kubernetes.io/force-ssl-redirect, are overwritten."
  type        = map(string)
  default     = {}
}

variable "storage_provisioner" {
  description = "Storage provisioner to use. See https://kubernetes.io/docs/concepts/storage/storage-classes/ for options."
  type        = string
  default     = ""
}

variable "storage_class_parameters" {
  description = "Storage class parameters. See https://kubernetes.io/docs/concepts/storage/storage-classes/#parameters for more information."
  type        = map(string)
  default     = {}
}
