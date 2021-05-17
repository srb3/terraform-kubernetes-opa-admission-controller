data "kubernetes_namespace" "system" {
  metadata {
    name = "kube-system"
  }
}

resource "null_resource" "add-label" {
  count = lookup(data.kubernetes_namespace.system.metadata.0.labels, "openpolicyagent.org/webhook", "") == "" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl label ns kube-system openpolicyagent.org/webhook=ignore"
  }

}

resource "null_resource" "remove-label" {

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl label namespaces kube-system openpolicyagent.org/webhook-"
  }
}

resource "kubernetes_namespace" "opa" {
  depends_on = [null_resource.add-label]
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name" : var.namespace
      "app.kubernetes.io/component" : "namespace"
      "openpolicyagent.org/webhook" : "ignore"
    }
  }
}

module "opa-tls" {
  source           = "./modules/tls"
  namespace        = kubernetes_namespace.opa.metadata.0.name
  cert_common_name = "${var.service_name}.${kubernetes_namespace.opa.metadata.0.name}.svc"
  ca_secret_name   = var.ca_secret_name
  cert_secret_name = var.cert_secret_name
  cert_dns_names   = ["${var.service_name}.${kubernetes_namespace.opa.metadata.0.name}.svc"]
}

resource "kubernetes_cluster_role_binding" "this-cluster-role-binding" {
  metadata {
    name = "opa-viewer"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "view"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:opa"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "this-role" {
  metadata {
    namespace = kubernetes_namespace.opa.metadata.0.name
    name      = "configmap-modifier"
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["update", "patch"]
  }
}

resource "kubernetes_role_binding" "this-role-binding" {
  metadata {
    namespace = kubernetes_namespace.opa.metadata.0.name
    name      = "opa-configmap-modifier"
  }
  role_ref {
    kind      = "Role"
    name      = "configmap-modifier"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:opa"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_service" "this-service" {
  metadata {
    name      = var.service_name
    namespace = kubernetes_namespace.opa.metadata.0.name
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "https"
      port        = 443
      protocol    = "TCP"
      target_port = 8443
    }
    selector = {
      app = var.service_name
    }
  }
}

resource "kubernetes_deployment" "this-service" {
  metadata {
    labels = {
      app = var.service_name
    }
    namespace = kubernetes_namespace.opa.metadata.0.name
    name      = var.service_name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.service_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.service_name
        }
      }
      spec {
        container {
          name  = "opa"
          image = "openpolicyagent/opa:0.28.0"
          args = [
            "run",
            "--server",
            "--tls-cert-file=/certs/tls.crt",
            "--tls-private-key-file=/certs/tls.key",
            "--addr=0.0.0.0:8443",
            "--addr=http://127.0.0.1:8181",
            "--log-format=json-pretty",
            "--set=decision_logs.console=true"
          ]
          volume_mount {
            read_only  = true
            mount_path = "/certs"
            name       = module.opa-tls.cert_secret_name
          }
        }
        container {
          name  = "kube-mgmt"
          image = "openpolicyagent/kube-mgmt:0.11"
          args = [
            "--replicate-cluster=v1/namespaces",
            "--replicate=extensions/v1beta1/ingresses"
          ]
        }
        volume {
          name = module.opa-tls.cert_secret_name
          secret {
            secret_name = module.opa-tls.cert_secret_name
            optional    = false
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "opa_default_system_main" {
  metadata {
    name      = "opa-default-system-main"
    namespace = kubernetes_namespace.opa.metadata.0.name
    annotations = {
      "openpolicyagent.org/policy-status" : "{}"
    }
  }
  data = {
    "main" : templatefile("${path.module}/templates/opa-default-system-main", {})
  }
  lifecycle {
    ignore_changes = [
      metadata.0.annotations["openpolicyagent.org/policy-status"]
    ]
  }
}

resource "kubernetes_manifest" "this-k8-manifest" {
  depends_on = [kubernetes_deployment.this-service]
  provider   = kubernetes-alpha
  manifest = {
    "apiVersion" = "admissionregistration.k8s.io/v1beta1"
    "kind"       = "ValidatingWebhookConfiguration"
    "metadata" = {
      "name" = "opa-validating-webhook"
    }
    "webhooks" = [
      {
        "clientConfig" = {
          "caBundle" = base64encode(trimspace(module.opa-tls.ca_cert))
          "service" = {
            "name"      = var.service_name
            "namespace" = kubernetes_namespace.opa.metadata.0.name
          }
        }
        "name" = "validating-webhook.openpolicyagent.org"
        "namespaceSelector" = {
          "matchExpressions" = [
            {
              "key"      = "openpolicyagent.org/webhook"
              "operator" = "NotIn"
              "values" = [
                "ignore",
              ]
            },
          ]
        }
        "rules" = [
          {
            "apiGroups" = [
              "*",
            ]
            "apiVersions" = [
              "*",
            ]
            "operations" = [
              "CREATE",
              "UPDATE",
            ]
            "resources" = [
              "*",
            ]
          },
        ]
      },
    ]
  }
}

resource "kubernetes_config_map" "this-config-map" {
  for_each = var.policies
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.opa.metadata.0.name
  }
  data = {
    "${each.key}.rego" : each.value.data
  }

  lifecycle {
    ignore_changes = [
      metadata.0.annotations["openpolicyagent.org/policy-status"]
    ]
  }

  depends_on = [kubernetes_manifest.this-k8-manifest]
}
