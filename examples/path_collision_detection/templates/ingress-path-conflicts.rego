package kubernetes.admission

import data.kubernetes.ingresses

operations = {"CREATE", "UPDATE"}

deny[msg] {
    some other_ns, other_ingress
    input.request.kind.kind == "Ingress"
    operations[input.request.operation]
    path := input.request.object.spec.rules[_].http.paths[_].path
    ingress := ingresses[other_ns][other_ingress]
    ingress.spec.rules[_].http.paths[_].path == path
    msg := sprintf("invalid ingress path %q (conflicts with %v/%v)", [path, other_ns, other_ingress])
}
