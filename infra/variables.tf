variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "owner_name" {
  type = string
}

variable "owner_email" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "secret_name_suffix" {
  type = string
}

variable "dns_hosted_zone_id" {
  type = string
}

variable "dns_suffix" {
  type = string
}

variable "prometheus_repo" {
  type = string
}

variable "prometheus_image_version" {
  type = string
}

variable "prometheus_cpu" {
  type    = number
  default = 512
}

variable "prometheus_mem" {
  type    = number
  default = 1024
}

variable "prometheus_port" {
  type    = number
  default = 9090
}

variable "prometheus_confluent_cloud_api_key" {
  type = string
}

variable "prometheus_confluent_cloud_api_secret" {
  type = string
}

variable "prometheus_alertmanager_url" {
  type = string
}

variable "prometheus_admin_password" {
  type = string
}

variable "grafana_repo" {
  type = string
}

variable "grafana_image_version" {
  type = string
}

variable "grafana_cpu" {
  type    = number
  default = 512
}

variable "grafana_mem" {
  type    = number
  default = 1024
}

variable "grafana_port" {
  type    = number
  default = 3000
}

variable "grafana_admin_password" {
  type = string
}

variable "grafana_prometheus_url" {
  type = string
}

variable "alertmanager_repo" {
  type = string
}

variable "alertmanager_image_version" {
  type = string
}

variable "alertmanager_cpu" {
  type    = number
  default = 512
}

variable "alertmanager_mem" {
  type    = number
  default = 1024
}

variable "alertmanager_port" {
  type    = number
  default = 9093
}

variable "alertmanager_webhook_url" {
  type = string
}