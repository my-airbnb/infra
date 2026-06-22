# Airbnb Clone — Infrastructure (Terraform + Ansible)

## The problem

Standing up a production cluster by hand is slow, **impossible to reproduce exactly**, and drifts
over time. Clicking through one cloud's console means **vendor lock-in** and no real
disaster-recovery story — if the box dies, so does the undocumented setup in someone's head.
How do you rebuild the entire platform, identically, **on any provider or bare metal**, from nothing?

## The approach — Infrastructure as Code

Two declarative stages turn a bare server into a fully configured GitOps cluster — reproducibly and
provider-agnostically, so the whole platform can be rebuilt from scratch with a handful of commands:

1. **Terraform** — provisions the cloud footprint (AWS).
2. **Ansible** — bootstraps the bare node into a GitOps-ready cluster.

Application workloads then deploy themselves via ArgoCD from
[`k8s-manifests`](https://github.com/my-airbnb/k8s-manifests).

> **Note:** values in this public repo are redacted — `YOUR_SERVER_IP`, the tfstate bucket's
> account id (`…-CHANGE_ME`), etc. Supply your own before running.

---

## Challenges I faced (and how I solved them)

Bootstrapping a GitOps cluster on a bare cloud node surfaced problems you don't get on a managed
control plane. Each of these is a real fix in the history:

- **No cloud load balancer on bare k3s.** The default `nginx-ingress` `Service` type expected a
  cloud LB that doesn't exist on a single self-managed node, so ingress never got an address. Set
  the service to bind the host ports directly so traffic actually reaches the cluster.
- **ArgoCD install failing on CRD ownership conflicts.** Re-applying the manifests collided with
  existing field owners. Added `--force-conflicts` to the install so the bootstrap is idempotent and
  re-runnable.
- **`kubeseal` install breaking on "latest".** Tracking the latest release pulled in a version that
  didn't match the in-cluster controller. Pinned a hardcoded, known-good version so sealing stays
  reproducible across rebuilds.

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
