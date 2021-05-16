.PHONY: all build test out clean

all: build test

build: build_prep build_platform

build_prep:
	@echo "Prep environment"
	terraform init

build_platform:
	@echo "Deploy Kong platform"
	terraform apply -auto-approve

test: test_path_collision

test_path_collision:
	@echo "ingress01 should succeed"
	kubectl apply -f test/fixtures/ingress01_external.yaml
	@echo ""
	@echo "ingress02 should fail"
	kubectl apply -f test/fixtures/ingress02_external.yaml || true
	@echo ""
	@echo "ingress03 should succeed"
	kubectl apply -f test/fixtures/ingress03_external.yaml

clean_test_path_collision:
	@echo "ingress01 cleaned"
	kubectl delete -f test/fixtures/ingress01_external.yaml
	@echo ""
	@echo "ingress03 cleaned"
	kubectl delete -f test/fixtures/ingress03_external.yaml

out:
	@echo "Platform endpoints"
	terraform output

clean:
	@echo "Cleaning up...."
	terraform destroy -auto-approve
