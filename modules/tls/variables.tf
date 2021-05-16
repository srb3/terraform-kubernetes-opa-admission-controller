variable "private_key_algorithm" {
  default = "RSA"
}

variable "private_key_rsa_bits" {
  default = "2048"
}

variable "validity_period_hours" {
  default = "26280"
}

variable "ca_allowed_uses" {
  default = []
}

variable "ca_common_name" {
  default = "admission_ca"
}

variable "namespace" {
  default = "opa"
}

variable "cert_common_name" {
  default = "opa.opa.svc"
}

variable "cert_dns_names" {
  default = ["opa.opa.svc"]
}

variable "cert_allowed_uses" {
  default = [
    "key_encipherment",
    "content_commitment",
    "digital_signature",
    "client_auth",
    "server_auth"
  ]
}

variable "cert_secret_name" {
  default = "opa-server"
}

variable "ca_secret_name" {
  default = "opa-server-ca"
}
