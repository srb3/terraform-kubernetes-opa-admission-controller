provider "kubernetes" {
  config_path = var.kube_config_file
}

provider "kubernetes-alpha" {
  config_path = var.kube_config_file
}

locals {
  ingress_conflicts = templatefile("${path.module}/templates/ingress-path-conflicts.rego", {})
}

module "opa-deploy" {
  source = "../../"
  policies = {
    "ingress-conflicts" = {
      data = local.ingress_conflicts
    }
  }
}

resource "kubernetes_namespace" "service01" {
  metadata {
    name = "service01"
  }
}

resource "kubernetes_namespace" "service02" {
  metadata {
    name = "service02"
  }
}

resource "kubernetes_namespace" "service03" {
  metadata {
    name = "service03"
  }
}
