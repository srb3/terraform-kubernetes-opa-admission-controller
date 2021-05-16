resource "tls_private_key" "this-ca" {
  algorithm = var.private_key_algorithm
  rsa_bits  = var.private_key_rsa_bits
}

resource "tls_self_signed_cert" "this-ca" {
  key_algorithm     = tls_private_key.this-ca.algorithm
  private_key_pem   = tls_private_key.this-ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.ca_allowed_uses

  subject {
    common_name = var.ca_common_name
  }

}

resource "kubernetes_secret" "this-ca-secret" {
  metadata {
    name      = var.ca_secret_name
    namespace = var.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.this-ca.cert_pem
    "tls.key" = tls_private_key.this-ca.private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "tls_private_key" "this-key" {
  algorithm = var.private_key_algorithm
  rsa_bits  = var.private_key_rsa_bits
}

resource "tls_cert_request" "this-cert-request" {
  key_algorithm   = tls_private_key.this-key.algorithm
  private_key_pem = tls_private_key.this-key.private_key_pem
  dns_names       = var.cert_dns_names
  subject {
    common_name = var.cert_common_name
  }
}

resource "tls_locally_signed_cert" "this-cert" {
  cert_request_pem   = tls_cert_request.this-cert-request.cert_request_pem
  ca_key_algorithm   = tls_private_key.this-ca.algorithm
  ca_private_key_pem = tls_private_key.this-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.this-ca.cert_pem

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.cert_allowed_uses
}

resource "kubernetes_secret" "this-cert-secret" {
  metadata {
    name      = var.cert_secret_name
    namespace = var.namespace
  }

  data = {
    "tls.crt" = tls_locally_signed_cert.this-cert.cert_pem
    "tls.key" = tls_private_key.this-key.private_key_pem
  }

  type = "kubernetes.io/tls"
}
