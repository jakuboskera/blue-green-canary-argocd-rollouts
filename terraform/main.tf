terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.0.13"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

provider "kind" {}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.my-cluster.endpoint
    cluster_ca_certificate = kind_cluster.my-cluster.cluster_ca_certificate
    client_certificate     = kind_cluster.my-cluster.client_certificate
    client_key             = kind_cluster.my-cluster.client_key
  }
}

resource "kind_cluster" "my-cluster" {
  name           = "my-cluster"
  wait_for_ready = "true"
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role  = "control-plane"
      image = "kindest/node:v1.23.4"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 32080
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 32443
        host_port      = 443
      }
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "4.9.11"
  create_namespace = true

  values = [
    file("../argocd/application.yaml")
  ]
}
