#!/bin/bash

echo "post-create start" >> ~/.status.log

# Clean up if clusters already exist
k3d cluster delete dev | tee -a ~/.status.log
k3d cluster delete platform | tee -a ~/.status.log
k3d cluster delete devtest-east | tee -a ~/.status.log
k3d cluster delete prod-east | tee -a ~/.status.log
k3d cluster delete managed | tee -a ~/.status.log

###################
# Managed Cluster #
###################
# Install the managed K3D cluster
k3d cluster create managed \
  --api-port=$(hostname -I | awk '{print $1}'):6550 \
  --config .devcontainer/manifests/k3d-managed.yaml \
  --wait | tee -a ~/.status.log

####################
# Platform Cluster #
####################
# Install the K3D cluster for Argo CD
k3d cluster create platform \
  --api-port=$(hostname -I | awk '{print $1}'):6551 \
  --config .devcontainer/manifests/k3d-platform.yaml \
  --wait | tee -a ~/.status.log

# Make sure we're on the right context
kubectx k3d-platform | tee -a ~/.status.log

# Install Argo CD using Helm
helm repo add argo https://argoproj.github.io/argo-helm | tee -a  ~/.status.log 
helm repo update | tee -a  ~/.status.log 
helm install argocd argo/argo-cd \
  --version 7.8.26 \
  --namespace argocd \
  --create-namespace \
  --set server.service.type="NodePort" \
  --set server.service.nodePortHttps=30179 \
  --set configs.cm."kustomize\.buildOptions"="--enable-helm" \
  --set configs.cm."application\.sync\.impersonation\.enabled"="false" \
  | tee -a  ~/.status.log 

########################
# DevTest-East Cluster #
########################
# Install the K3D cluster for Argo CD
k3d cluster create devtest-east \
  --api-port=$(hostname -I | awk '{print $1}'):6552 \
  --config .devcontainer/manifests/k3d-devtest-east.yaml \
  --wait | tee -a ~/.status.log

# Make sure we're on the right context
kubectx k3d-devtest-east | tee -a ~/.status.log

# Install Argo CD using Helm
helm repo add argo https://argoproj.github.io/argo-helm | tee -a  ~/.status.log 
helm repo update | tee -a  ~/.status.log 
helm install argocd argo/argo-cd \
  --version 7.8.26 \
  --namespace argocd \
  --create-namespace \
  --set server.service.type="NodePort" \
  --set server.service.nodePortHttps=31179 \
  --set configs.cm."kustomize\.buildOptions"="--enable-helm" \
  --set configs.cm."application\.sync\.impersonation\.enabled"="false" \
  | tee -a  ~/.status.log 

#####################
# Prod-East Cluster #
#####################
# Install the K3D cluster for Argo CD
k3d cluster create prod-east \
  --api-port=$(hostname -I | awk '{print $1}'):6553 \
  --config .devcontainer/manifests/k3d-prod-east.yaml \
  --wait | tee -a ~/.status.log

# Make sure we're on the right context
kubectx k3d-prod-east | tee -a ~/.status.log

# Install Argo CD using Helm
helm repo add argo https://argoproj.github.io/argo-helm | tee -a  ~/.status.log 
helm repo update | tee -a  ~/.status.log 
helm install argocd argo/argo-cd \
  --version 7.8.26 \
  --namespace argocd \
  --create-namespace \
  --set server.service.type="NodePort" \
  --set server.service.nodePortHttps=32179 \
  --set configs.cm."kustomize\.buildOptions"="--enable-helm" \
  --set configs.cm."application\.sync\.impersonation\.enabled"="false" \
  | tee -a  ~/.status.log 

echo "post-create complete" >> ~/.status.log
