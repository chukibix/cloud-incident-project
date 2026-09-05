# Cloud Incident Platform

A fully reproducible AWS infrastructure project: a NestJS backend, PostgreSQL (RDS), and a Kubernetes-based monitoring stack (Prometheus + Grafana), provisioned entirely from code. The whole environment can be destroyed and rebuilt from scratch with two commands : `terraform destroy` and `terraform apply` . with zero manual setup steps in between.

This project was built as a hands-on exploration of Infrastructure as Code, GitOps, and observability, targeting DevOps/SRE workflows.

---

## Architecture overview

<img width="1156" height="1123" alt="Untitled Diagram" src="https://github.com/user-attachments/assets/5c336b9c-70af-4d04-af5e-b3023a400801" />


**Two independent lifecycles, on purpose:**
- **Infrastructure** (VPC, EC2, RDS, IAM) , changes rarely, via `terraform apply`/`destroy`.
- **Application** (backend code) , changes often, via `git push` → CI/CD → auto-deployed by ArgoCD, with no infrastructure changes required.

---

## Tech stack

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform |
| Compute | AWS EC2 (single node, `t3.medium`) |
| Database | AWS RDS (PostgreSQL) |
| Container orchestration | k3s (lightweight Kubernetes) |
| Ingress | Traefik (bundled with k3s) |
| GitOps / Continuous Deployment | ArgoCD |
| CI | GitHub Actions |
| Container registry | Amazon ECR |
| Monitoring | Prometheus, Grafana, kube-state-metrics, node-exporter |
| AWS metrics bridge | yace (yet-another-cloudwatch-exporter) — feeds RDS CloudWatch metrics into Prometheus |
| Application | NestJS (TypeScript) + TypeORM |
| Security scanning | Trivy (image vulnerability scanning), Hadolint (Dockerfile linting) |

---

## Repository structure

```
cloud-incident-platform/
├── backend/                   # NestJS application
│   ├── src/
│   ├── k8s/
│   │   ├── backend-deployment.yaml   # App Deployment (image tag updated by CI)
│   │   ├── backend-service.yaml      # ClusterIP Service
│   │   ├── backend-ingress.yaml      # Traefik Ingress rule
│   │   └── argocd-application.yaml   # Tells ArgoCD to watch this folder
│   └── Dockerfile
├── monitoring/
│   ├── yace-values.yaml              # CloudWatch exporter config (RDS metrics)
│   ├── yace-servicemonitor.yaml
│   ├── rds-ca.pem                    # AWS RDS CA bundle (public, not a secret)
│   └── dashboards/
│       └── cloud-incident-dashboard.json  # Provisioned automatically into Grafana
├── terraform/
│   ├── main.tf                # VPC, subnets, EC2, RDS, security groups
│   ├── iam.tf                 # IAM role + policies for the EC2 instance
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
│       └── user_data.sh.tpl   # EC2 boot script (installs k3s, Helm, ArgoCD, etc.)
└── .github/workflows/
    └── deploy.yml              # CI: build, scan, push image, update manifest
```

---

## How infrastructure comes up (from zero)

1. `terraform apply` creates the AWS networking layer (VPC, public + private subnets, Internet Gateway, route tables), a security group (SSH locked to the caller's current IP via a live lookup, HTTP open), an IAM role scoped to exactly what the instance needs (ECR pull, CloudWatch read, SSM access), the RDS Postgres instance, and the EC2 instance itself.
2. The EC2 instance's `user_data` script runs once, automatically, at first boot:
   - Installs k3s and Helm
   - Installs `kube-prometheus-stack` (Prometheus, Grafana, Alertmanager) via Helm
   - Installs `yace`, configured to pull RDS CloudWatch metrics
   - Provisions a custom Grafana dashboard from a JSON file in this repo
   - Installs ArgoCD
   - Creates the Kubernetes Secrets the backend needs (DB credentials, RDS CA cert, ECR pull credentials) , all values sourced from Terraform variables or generated fresh (the ECR token is regenerated at every boot rather than reused, so it never goes stale)
   - Applies a single ArgoCD `Application` resource pointing at `backend/k8s/` in this repo
3. From that point on, ArgoCD takes over: it watches `backend/k8s/` in GitHub directly and keeps the cluster's Deployment/Service/Ingress in sync with whatever is committed there , independent of the boot script, for the lifetime of the instance.

**Why this matters:** every value that changes between rebuilds (the RDS endpoint, the current IP allowed to SSH in, secrets) is injected dynamically at boot time via Terraform's `templatefile()` , nothing is hardcoded, so `destroy` → `apply` reliably produces a working environment every time.

---

## How application changes ship (CI/CD)

1. A commit is pushed to `backend/` on `main`.
2. GitHub Actions:
   - Lints the Dockerfile (Hadolint)
   - Builds the Docker image, tagged with the short Git SHA
   - Scans the image for critical/high vulnerabilities (Trivy) , the pipeline fails the push if the scan fails
   - Pushes the verified image to Amazon ECR
   - Patches `backend/k8s/backend-deployment.yaml` with the new image tag and commits that change back to `main`
3. ArgoCD (already running in the cluster, polling GitHub independently) detects the manifest change on its next sync, and rolls out the new image , no SSH, no manual `kubectl`, no infrastructure changes required.

This means: **infrastructure changes require `terraform apply`; application changes require only a `git push`.**

---

## Observability

- **Grafana** dashboards (provisioned as code, not built by hand in the UI) cover: RDS CPU/storage/swap (via CloudWatch → yace → Prometheus), backend pod distribution, live pod counts, and a yace health check panel.
- **Prometheus** scrapes cluster-internal metrics (via kube-state-metrics and node-exporter) and CloudWatch-derived RDS metrics (via yace).
- Access is intentionally **not public**: Grafana and ArgoCD's UIs are reached via SSH tunnel + `kubectl port-forward`, not exposed to the internet. This was a deliberate choice , these are admin surfaces, and the backend API is the only thing meant to be publicly reachable (via the Traefik Ingress).

```bash
ssh -i <key>.pem -L 3000:localhost:3000 ubuntu@<ec2-public-ip>
# then, on the instance:
sudo kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# then open http://localhost:3000 locally
```

---

## Running this yourself

**Prerequisites:** an AWS account, Terraform installed, AWS CLI configured with credentials.

```bash
git clone https://github.com/chukibix/cloud-incident-project.git
cd cloud-incident-project/terraform

# Create terraform.tfvars with at minimum:
#   db_password = "<a-strong-password-no-special-chars-like-/-@-"->
echo 'db_password = "YourStrongPassword123!"' > terraform.tfvars

terraform init
terraform plan     # review what will be created
terraform apply    # takes a few minutes; boot script provisions the full stack

terraform output ec2_public_ip   # once apply finishes
```

Give the instance a few minutes after `apply` completes for the boot script to finish installing everything. Then:

```bash
curl http://<ec2-public-ip>/simulations/health
```

To tear everything down:

```bash
terraform destroy
```

---

## Notable design decisions

- **RDS endpoint and DB credentials are never hardcoded** , they're injected into Kubernetes Secrets at boot time from Terraform outputs, so the backend's manifest in Git stays static and portable across rebuilds.
- **The security group's SSH rule uses a live IP lookup** (`data "http" "my_ip"`) rather than a hardcoded CIDR, so it self-corrects on every `apply` regardless of where it's run from.
- **The backend Deployment has explicit CPU/memory `requests` and `limits`**, so a single misbehaving or load-tested pod cannot starve the rest of the node (Traefik, ArgoCD, monitoring).
- **`user_data_replace_on_change = true`** ensures any change to the boot script forces a genuinely fresh instance on the next `apply`, rather than silently reusing a stale one (cloud-init only runs `user_data` once per instance, on first boot).

---

## Known limitations / possible next steps

- TypeORM's `synchronize: true` is used for schema management; a real production setup would use migrations instead, since concurrent replica startups can race on schema creation.
- The EC2 instance is a single node , no high availability. A production version would move to a managed Kubernetes service (EKS) with multiple nodes.
- Grafana/ArgoCD access via SSH tunnel is intentional for this project's threat model, but a team setting would likely use a VPN or SSO-backed ingress instead.
