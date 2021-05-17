# Path Collision Detection

This example calls the OPA module to deploy the OPA admission controller
and passes through a rego policy file. That policy checks for ingress
path collisions. If a collision is detected by OPA then the create
request is denied before it gets to Kubernetes.

## Status

Not intended for production use, with code is used for
deploying the admission controller in a testing capacity
to facilitate testing OPA policies.

## Prerequisites

The example set up to run without any modifcation. But make sure
you have Terraform installed, and a kube config file that points to a
working and accessible Kubernetes cluster. If your kube config file is in a
non default location then you will need to update kube_config_file variable
in the [variables.tf](./variables.tf) or override it with a [terraform.tfvars](https://www.terraform.io/docs/language/values/variables.html#variable-definitions-tfvars-files)
file or at [run time](https://www.terraform.io/docs/language/values/variables.html#environment-variables)

### Usage

``` bash
make build
make test
```

### Test data

The test data is located [here](./examples/path_collision_detection/test/fixtures)

#### Test data content

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
Warning: extensions/v1beta1 Ingress is deprecated in v1.14+, unavailable in v1.22+; use networking.k8s.io/v1 Ingress
ingress.extensions/external-service03 created

ingress03 patch should fail
kubectl -n service03 patch -f test/fixtures/ingress03_external.yaml --type="strategic" --patch-file test/fixtures/ingress03_patch_external.yaml || true
Error from server (invalid ingress path "/mock" (conflicts with service01/external-service01)): admission webhook "validating-webhook.openpolicyagent.org" denied the request: invalid ingress path "/mock" (conflicts with service01/external-service01)

```

#### Destroy

``` bash
make clean
```
