output "ca_cert" {
  value = tls_self_signed_cert.this-ca.cert_pem
}

output "ca_key" {
  value     = tls_private_key.this-ca.private_key_pem
  sensitive = true
}

output "cert" {
  value     = tls_locally_signed_cert.this-cert
  sensitive = true
}

output "key" {
  value     = tls_private_key.this-key
  sensitive = true
}

output "cert_secret_name" {
  value = kubernetes_secret.this-cert-secret.metadata.0.name
}

output "ca_secret_name" {
  value = kubernetes_secret.this-ca-secret.metadata.0.name
}
