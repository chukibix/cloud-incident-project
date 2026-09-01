#!/bin/bash
set -e

# ---------- k3s ----------
curl -sfL https://get.k3s.io | sh -

until sudo k3s kubectl get nodes 2>/dev/null; do sleep 5; done

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config
echo 'export KUBECONFIG=/home/ubuntu/.kube/config' >> /home/ubuntu/.bashrc

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# ---------- Helm ----------
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ---------- monitoring namespace ----------
kubectl create namespace monitoring

# ---------- kube-prometheus-stack ----------
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring

# ---------- yace ----------
helm repo add yace https://nerdswords.github.io/helm-charts
helm repo update

git clone https://github.com/chukibix/cloud-incident-project.git /tmp/cloud-incident-project

helm install yace yace/yet-another-cloudwatch-exporter \
  -n monitoring \
  -f /tmp/cloud-incident-project/monitoring/yace-values.yaml

kubectl apply -f /tmp/cloud-incident-project/monitoring/yace-servicemonitor.yaml

# ---------- Grafana dashboard provisioning ----------
kubectl create configmap cloud-incident-dashboard \
  --from-file=cloud-incident-dashboard.json=/tmp/cloud-incident-project/monitoring/dashboards/cloud-incident-dashboard.json \
  -n monitoring \
  --dry-run=client -o yaml | \
  kubectl label --local -f - grafana_dashboard=1 -o yaml | \
  kubectl apply -f -

# ---------- ArgoCD ----------
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# wait for argocd server to be ready before continuing
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

sudo apt-get update
sudo apt-get install -y unzip

# ---------- AWS CLI ----------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# ---------- secrets for backend ----------

# ECR pull secret — generated fresh, so it's never stale/expired
ECR_PASSWORD=$(aws ecr get-login-password --region eu-west-3)
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=${ecr_repo_url} \
  --docker-username=AWS \
  --docker-password="$ECR_PASSWORD" \
  --namespace=default

# DB credentials — values injected by Terraform via templatefile()
kubectl create secret generic cloud-db-secret \
  --from-literal=DB_USERNAME=postgres \
  --from-literal=DB_PASSWORD='${db_password}' \
  --from-literal=DB_DATABASE=${db_name} \
  --from-literal=DB_HOST='${db_host}' \
  --namespace=default

# RDS CA cert — pulled from the repo, not a secret value itself
kubectl create secret generic cloud-db-ca \
  --from-file=ca.crt=/tmp/cloud-incident-project/monitoring/rds-ca.pem \
  --namespace=default

# ---------- backend app, via ArgoCD ----------
kubectl apply -f /tmp/cloud-incident-project/backend/k8s/argocd-application.yaml
