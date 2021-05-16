# terraform-kubernetes-opa-admission-controller

A Terraform module for provisioning an OPA admission controller onto Kubernetes

## Status

Not intended for production use, with code is used for
deploying the admission controller in a testing capacity
to facilitate testing OPA policies.

## Prerequisites

### Using the module

This module utilises the Terraform Kubernetes provider (both alpha and stable)
, so when including this module in your code you will need to specify
the provider and args e.g.

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}
```

## Usage

```hcl
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
```

An examples of how to use the module is in the examples directory.
Currently there is only a path collision detection example.

The `path_collision_detection` deploys OPA admission controller,
with one policy. The policy denies the creation of ingress entries
if another entry exists with the same path. This use case is designed to
work with the Kong ingress controller.

## Testing

### Path collision

* A Kubernetes environment to use with kube config file at `~/.kube/config`

#### Run

From the [path_collision_detection](./examples/path_collision_detection)
directiory run:

``` bash
make build
make test
```

#### Test data

The test data is located [here](./examples/path_collision_detection/test/fixtures)
content:

ingress01_external.yaml:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: external-service01
  annotations:
    kubernetes.io/ingress.class: kong-kic1
  namespace: service01
spec:
  rules:
    - host: www.test.example.com
      http:
        paths:
          - path: /mock
            backend:
              serviceName: service01
              servicePort: 80

```

ingress02_external.yaml:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: external-service02
  annotations:
    kubernetes.io/ingress.class: kong-kic1
  namespace: service02
spec:
  rules:
    - host: www.test.example.com
      http:
        paths:
          - path: /mock
            backend:
              serviceName: service02
              servicePort: 80

```

ingress03_external.yaml:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: external-service03
  annotations:
    kubernetes.io/ingress.class: kong-kic1
  namespace: service03
spec:
  rules:
    - host: www.test.example.com
      http:
        paths:
          - path: /mocks
            backend:
              serviceName: service03
              servicePort: 80

```

#### Results

``` bash
$> make test

ingress01 should succeed
kubectl apply -f test/fixtures/ingress01_external.yaml
ingress.extensions/external-service01 created

ingress02 should fail
kubectl apply -f test/fixtures/ingress02_external.yaml || true
Error from server (invalid ingress path "/mock" (conflicts with service01/external-service01)): error when creating "test/fixtures/ingress02_external.yaml": admission webhook "validating-webhook.openpolicyagent.org" denied the request: invalid ingress path "/mock" (conflicts with service01/external-service01)

ingress03 should succeed
kubectl apply -f test/fixtures/ingress03_external.yaml
ingress.extensions/external-service03 created


```

#### Destroy

``` bash
make clean
```
