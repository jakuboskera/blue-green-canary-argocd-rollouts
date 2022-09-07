# Blue-green and canary deployment strategy using ArgoCD and Argo Rollouts

This repository shows
[Argo Rollouts](https://argoproj.github.io/argo-rollouts/) in action.
Argo Rollouts is Kubernetes progressive delivery controller.
It expands the possibilities of more complex Kubernetes deployment strategies,
like deployments

1. [Blue-green](https://argoproj.github.io/argo-rollouts/features/bluegreen/)
1. [Canary](https://argoproj.github.io/argo-rollouts/features/canary/)
   1. with [traffic management](https://argoproj.github.io/argo-rollouts/features/traffic-management/)
   1. with [analysis](https://argoproj.github.io/argo-rollouts/features/analysis/)

Examples of these two types of deployments are shown in this repository.
See [Get started](#-get-started).

Creation and management of a Kubernetes cluster on
[kind](https://kind.sigs.k8s.io) is done via
[Terraform](https://www.terraform.io) and
[Argo CD](https://argo-cd.readthedocs.io/en/stable).

## 📖 TOC

- [Canary and blue-green deployment strategy using Argo Rollouts](#canary-and-blue-green-deployment-strategy-using-argo-rollouts)
  - [📖 TOC](#-toc)
  - [⚠️ Prerequisites](#️-prerequisites)
  - [🏁 Get started](#-get-started)
    - [🚀 Create an infrastructure](#-create-an-infrastructure)
    - [🟦🟩 Simulate a blue-green deployment](#-simulate-a-blue-green-deployment)
      - [Procedure](#procedure)
    - [🦜 Simulate a canary deployment](#-simulate-a-canary-deployment)
    - [🧹 Destroy an infrastructure](#-destroy-an-infrastructure)
  - [🙋‍♂️ FAQ](#️-faq)
    - [How to get initial argocd password for user `admin`](#how-to-get-initial-argocd-password-for-user-admin)
    - [How to access to ArgoCD](#how-to-access-to-argocd)
    - [How to access to Prometheus](#how-to-access-to-prometheus)

## ⚠️ Prerequisites

1. Docker installed
1. Terraform CLI installed
1. Kubectl CLI installed

## 🏁 Get started

1. Fork this repository (you need to have a fork of this repository in order
   to make some commits to simulate a deployment of a new versions
   of applications)
1. Clone your forked repo

    ```bash
    git clone https://github.com/<gh_username>/blue-green-canary-argocd-rollouts.git
    ```

1. Navigate to a folder `blue-green-canary-argocd-rollouts`

    ```bash
    cd blue-green-canary-argocd-rollouts
    ```

1. Replace value of `repoURL` of ArgoCD applications to your GitHub repository

    ```bash
    make replace-repourl URL=https://github.com/<gh_username>/blue-green-canary-argocd-rollouts.git
    ```

1. Commit and push these changes

### 🚀 Create an infrastructure

1. Create an infrastructure based on `terraform/main.tf`

    ```bash
    make tf-apply
    ```

1. After some minutes (max 5) there will be running

   1. 1-node K8s cluster
   1. ArgoCD
   1. Argo Rollouts
   1. ingress-nginx
   1. Prometheus
   1. blue-green app
   1. canary app

1. After that when infrastructure is in place it automatically deploys all
   aplications from Helm Chart `argocd/apps`. These applications are
   [Helm Charts](https://helm.sh), defined in `charts/` folder
1. See [FAQ](#faq) for more questions

### 🟦🟩 Simulate a blue-green deployment

As far as infrastructure is up and running you can use this procedure
to simulate a blue-green deployment.

In this procedure we will have
1. two URLs:

   1. <http://blue-green.local> - stable version, considered like "production"
      version where production traffic goes to
   1. <http://blue-green-preview.local> - preview version, considered like
      a potencionally new version of the application, but before going to
      production we have abillity to test it

1. two versions of simple blue-green app (presented by container images):

   1. `jakuboskera/blue-green:blue` - blue background color
   1. `jakuboskera/blue-green:green` - green background color

#### Procedure

1. [Get initial admin password for ArgoCD](#how-to-get-initial-argocd-password-for-user-admin)
   and [access ArgoCD UI](#how-to-access-to-argocd)
1. Check that `blue-green` application was deployed
1. Open your `/etc/hosts` file and add there these local DNS records, save that
   file

    ```bash
    # /etc/hosts

    127.0.0.1 blue-green.local # stable/active version
    127.0.0.1 blue-green-preview.local # preview version
    ```

1. Try to visit <http://blue-green.local>, you should see a webpage with blue
   background color (wait for DNS, it could take some seconds to take an
   effect)
1. Also when you visit <http://blue-green-preview.local> you will see a blue
   version, because this is a first deployment
1. If so, everything is correct and now you can deploy a new version of this
   app (with a green background color)
1. Go to your forked repository and open a file
   `argocd/apps/templates/blue-green.yaml`

   1. If value of `.spec.source.helm.parameters[0].value` is `blue` change it
   `green`, if `green` change it to `blue`
   1. Commit these changes

1. Go back to ArgoCD UI and open the application `blue-green`, you will see
   that after some seconds **App Health** is now in **Suspended** state, which
   means that application on URL <http://blue-green.local> is still in **blue**
   version, but desired state (from git) is **green** version.

   Without Argo Rollouts, ArgoCD would normally sync the desired state
   and application would be now in **green** version. Hovewer here is where
   Argo Rollouts comes into play, because now you have a possibility to inspect
   a new version before it is switched to "production" and see if the new
   version is ok.

   To inspect the new green version before switching visit
   <http://blue-green-preview.local>.

   (If you don't see a green version it have not been probably sync yet,
   in this case go to ArgoCD UI and refresh a blue-green app.)

1. As far as you are satisfied with a potential new version of the app
   you can click in ArgoCD UI -> application `blue-green` -> options
   (three dots) on rollout `blue-green` -> Promote-Full

1. Now when you visit <http://blue-green.local>, you can see that a new version of
   `blue-green` application is in place (green background color)

1. (Optional) You can repeat steps 7-10 how many times you want, just
   interchange `blue` for `green` and `green` for `blue`

1. That was an example of a blue-green deployment strategy in Kubernetes
   using Argo Rollouts using GitOps principles

### 🦜 Simulate a canary deployment

TODO

### 🧹 Destroy an infrastructure

To destroy infrastructure based on `terraform/main.tf`

```bash
make tf-destroy
```

## 🙋‍♂️ FAQ

### How to get initial argocd password for user `admin`

```bash
make argocd-get-password
```

### How to access to ArgoCD

To port-forward to ArgoCD, it will be available on <http://localhost:8080>

```bash
make argocd-port-forward
```

### How to access to Prometheus

To port-forward to Prometheus, it will be available on <http://localhost:8090>

```bash
make prometheus-port-forward
```
