.ONESHELL:
.SHELL := /bin/bash
.DEFAULT_GOAL := help

# TODO
.PHONY: help pre-commit-install pre-commit-all tf-apply tf-destroy argocd-get-password argocd-port-forward

help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

pre-commit-install: ## Install pre-commit into your git hooks. After that pre-commit will now run on every commit
	pre-commit install

pre-commit-all: ## Manually run all pre-commit hooks on a repository (all files)
	pre-commit run --all-files

tf-init: ## Make terraform init
	terraform -chdir=terraform init

tf-apply: tf-init ## Creates infrastructure based on terraform/main.tf using terraform
	terraform -chdir=terraform apply -auto-approve

tf-destroy: ## Destroys infrastructure based on terraform/main.tf using terraform
	terraform -chdir=terraform apply -destroy -auto-approve

replace-repourl: ## Replace repoURL to URL of your forked repository, parameter URL must be set
	test -n "$(URL)"
	sed -i '' -e "s|https://github.com/jakuboskera/blue-green-canary-argocd-rollouts.git|$(URL)|" argocd/{apps/values,application}.yaml

argocd-get-password: ## Gets initial password of ArgoCD installation, username is admin
	kubectl --kubeconfig terraform/my-cluster-config -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

argocd-port-forward: ## Port-forward to ArgoCD, it will be then accessible on http://localhost:8080
	kubectl --kubeconfig terraform/my-cluster-config -n argocd port-forward svc/argocd-server 8080:80

prometheus-port-forward: ## Port-forward to Prometheus, it will be then accessible on http://localhost:8090
	kubectl --kubeconfig terraform/my-cluster-config -n monitoring port-forward svc/kube-prometheus-stack-prometheus 8090:9090

# TODO: add targets

# New targets here
