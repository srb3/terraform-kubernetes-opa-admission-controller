variable "namespace" {
  default = "opa"
}

variable "service_name" {
  default = "opa"
}

variable "ca_secret_name" {
  default = "opa-server-ca"
}

variable "cert_secret_name" {
  default = "opa-server"
}

variable "policies" {
  description = "A map of OPA policy objects"
  type = map(object({
    data = string
  }))
  default = {}
}
