#!/bin/bash

echo "post-start start" >>  ~/.status.log 

# this runs in background each time the container starts

####################################
# Prod-East Cluster Setup on Start #
####################################

# Verify that the Prod-East cluster exists
if [[ $(k3d cluster list | grep prod-east | wc -l) -eq 0 ]]; then
    echo "Prod-East cluster not found. Exiting." | tee -a  ~/.status.log
    exit 1
fi

# Make sure we're on the right context
kubectx k3d-prod-east | tee -a ~/.status.log

# Ensure kubeconfig is set up.
# k3d kubeconfig merge prod-east --kubeconfig-merge-default | tee -a ~/.status.log 

# Wait for Argo CD to be ready
kubectl rollout status -n argocd sts/argocd-application-controller | tee -a  ~/.status.log

# Wait for the port to be ready
counter=0
until [[ $(curl -s -o /dev/null -w "%{http_code}" localhost:32179) -eq 307 ]]
do
    echo "Waiting for Argo CD endpoint to be ready..." | tee -a  ~/.status.log
    sleep 3
    counter=$((counter+1))
    if [[ $counter -gt 60 ]]; then
        echo "Port not available for Argo CD CLI" | tee -a  ~/.status.log
        exit 1
    fi
done

# Update Argo CD Admin Password
argopass=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)
argouri="localhost:32179"
argonewpass="password"
argocd login --insecure --username ${argouser:=admin} --password ${argopass} --grpc-web ${argouri} | tee -a  ~/.status.log 
argocd account --insecure update-password --insecure --current-password ${argopass} --new-password ${argonewpass} | tee -a  ~/.status.log 

# Update Argo CD to use cluster-admin service account for sync operations in the "default" project
kubectl apply -f .devcontainer/manifests/argocd-configupdate.yaml | tee -a  ~/.status.log

#######################################
# DevTest-East Cluster Setup on Start #
#######################################

# Verify that the DevTest-East cluster exists
if [[ $(k3d cluster list | grep devtest-east | wc -l) -eq 0 ]]; then
    echo "DevTest-East cluster not found. Exiting." | tee -a  ~/.status.log
    exit 1
fi

# Make sure we're on the right context
kubectx k3d-devtest-east | tee -a ~/.status.log

# Ensure kubeconfig is set up.
# k3d kubeconfig merge devtest-east --kubeconfig-merge-default | tee -a ~/.status.log 

# Wait for Argo CD to be ready
kubectl rollout status -n argocd sts/argocd-application-controller | tee -a  ~/.status.log

# Wait for the port to be ready
counter=0
until [[ $(curl -s -o /dev/null -w "%{http_code}" localhost:31179) -eq 307 ]]
do
    echo "Waiting for Argo CD endpoint to be ready..." | tee -a  ~/.status.log
    sleep 3
    counter=$((counter+1))
    if [[ $counter -gt 60 ]]; then
        echo "Port not available for Argo CD CLI" | tee -a  ~/.status.log
        exit 1
    fi
done

# Update Argo CD Admin Password
argopass=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)
argouri="localhost:31179"
argonewpass="password"
argocd login --insecure --username ${argouser:=admin} --password ${argopass} --grpc-web ${argouri} | tee -a  ~/.status.log 
argocd account --insecure update-password --insecure --current-password ${argopass} --new-password ${argonewpass} | tee -a  ~/.status.log 

# Update Argo CD to use cluster-admin service account for sync operations in the "default" project
kubectl apply -f .devcontainer/manifests/argocd-configupdate.yaml | tee -a  ~/.status.log

###################################
# Platform Cluster Setup on Start #
###################################

# Verify that the Platform cluster exists
if [[ $(k3d cluster list | grep platform | wc -l) -eq 0 ]]; then
    echo "Platform cluster not found. Exiting." | tee -a  ~/.status.log
    exit 1
fi

# Make sure we're on the right context
kubectx k3d-platform | tee -a ~/.status.log

# Ensure kubeconfig is set up. 
# k3d kubeconfig merge platform --kubeconfig-merge-default | tee -a ~/.status.log 

# Update the repo for the workshop

# DANE: This script looks like it needs to run in a GitHub Codespace, so I'm going to comment it out for now.
# bash .devcontainer/scripts/update-repo-for-workshop.sh | tee -a  ~/.status.log 

# Wait for Argo CD to be ready
kubectl rollout status -n argocd sts/argocd-application-controller | tee -a  ~/.status.log

# Wait for the port to be ready
counter=0
until [[ $(curl -s -o /dev/null -w "%{http_code}" localhost:30179) -eq 307 ]]
do
    echo "Waiting for Argo CD endpoint to be ready..." | tee -a  ~/.status.log
    sleep 3
    counter=$((counter+1))
    if [[ $counter -gt 60 ]]; then
        echo "Port not available for Argo CD CLI" | tee -a  ~/.status.log
        exit 1
    fi
done

# Update Argo CD Admin Password
argopass=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)
argouri="localhost:30179"
argonewpass="password"
argocd login --insecure --username ${argouser:=admin} --password ${argopass} --grpc-web ${argouri} | tee -a  ~/.status.log 
argocd account --insecure update-password --insecure --current-password ${argopass} --new-password ${argonewpass} | tee -a  ~/.status.log 

######### Add External Clusters
argocd cluster add -y k3d-devtest-east | tee -a  ~/.status.log
argocd cluster add -y k3d-prod-east | tee -a  ~/.status.log
argocd cluster list | tee -a  ~/.status.log

# Patch URL value. Probably can do this via helm in the "post-create.sh" script. PRs are welcome

# DANE: I expect this to fail when running locally, so I'm going to see what I get without it.
# kubectl patch cm/argocd-cm -n argocd --type=json  -p="[{\"op\": \"replace\", \"path\": \"/data/url\", \"value\":\"https://${CODESPACE_NAME}-30179.app.github.dev\"}]" | tee -a  ~/.status.log

# Update Argo CD to use cluster-admin service account for sync operations in the "default" project
kubectl apply -f .devcontainer/manifests/argocd-configupdate.yaml | tee -a  ~/.status.log

# Best effort env load
source ~/.bashrc

echo "post-start complete" >>  ~/.status.log 
