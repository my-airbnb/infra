# Airbnb Clone — Infrastructure (Terraform + Ansible)

Infrastructure-as-Code that **provisions** and **bootstraps** the k3s cluster the
[Airbnb-clone microservices platform](https://github.com/my-airbnb/k8s-manifests) runs on.

Two stages:

1. **Terraform** — provisions the cloud infrastructure (AWS).
2. **Ansible** — turns the bare node into a fully configured GitOps cluster.

> **Note:** values in this public repo are redacted — `YOUR_SERVER_IP`, the tfstate bucket's
> account id (`…-CHANGE_ME`), etc. Supply your own before running.

---

## 1. Terraform — `terraform/`

Provisions the AWS footprint for a single-node k3s host:

| File | Provisions |
|------|-----------|
| `vpc.tf` | VPC, subnet, internet gateway, routing |
| `security_groups.tf` | Firewall rules (SSH, HTTP/HTTPS, k3s API) |
| `ec2.tf` | Ubuntu EC2 instance (the k3s node) + Elastic IP |
| `outputs.tf` | Public IP + ready-to-use SSH command |
| `variables.tf` | Region, instance type, key-pair name, etc. |
| `backend.tf` | Remote state in an encrypted **S3** backend |

```bash
cd terraform
terraform init
terraform apply        # outputs the public IP + ssh command
```

## 2. Ansible — `ansible/`

Configures the provisioned node into a working GitOps cluster. Point
`inventory.yml` at the host (`ansible_host`), then run the playbooks:

| Playbook | Installs / configures |
|----------|----------------------|
| `k3s.yml` | Lightweight Kubernetes (k3s) |
| `helm.yml` | Helm package manager |
| `nginx-ingress.yml` | Ingress / Gateway data-plane |
| `cert-manager.yml` | TLS certificate automation |
| `sealed-secrets.yml` | Bitnami Sealed Secrets controller (+ exports the public cert) |
| `argocd.yml` | ArgoCD (GitOps controller) |
| `argocd-app.yml` | Registers the root ArgoCD `Application` → starts watching `k8s-manifests` |
| `falco.yml` | Runtime security / threat detection |

```bash
cd ansible
# edit inventory.yml: set ansible_host + your SSH key
make all          # or: ansible-playbook -i inventory.yml playbooks/<playbook>.yml
```

---

## How it fits together

```
  terraform apply ─▶ AWS VPC + EC2 (k3s node) + EIP
                          │
  ansible-playbook ─▶ k3s · helm · ingress · cert-manager
                       · sealed-secrets · argocd · falco
                          │
  argocd-app.yml ─▶ ArgoCD starts watching  my-airbnb/k8s-manifests (infra branch)
                          │
                     cluster self-deploys every microservice (GitOps)
```

Application workloads (the 15 microservices, databases, gateway routes, sealed secrets) live in
the **[k8s-manifests](https://github.com/my-airbnb/k8s-manifests)** repo, which ArgoCD reconciles
automatically. This repo only stands up the platform they run on.
