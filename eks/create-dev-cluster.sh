#!/bin/bash

AWS_REGION="ap-south-1"
EKS_CLUSTER_NAME="dev"
SSK_PUBLIC_KEY="/home/evex/.ssh/eks-key-pair.pub"
NODEGROUP_NAME="standard-workers-$(date +%d-%m-%Y)"
NODE_MIN="1"
NODE_MAX="15"
NODE_VOLUME_SIZE="20"
NODE_SIZE="t3.large"

#upgrade kubectl

#upgrade eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

#upgrade helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | sudo bash


#provision EKS cluster
eksctl get cluster --name $EKS_CLUSTER_NAME 
if [[ $? == "0" ]]
then
    STATUS=$(eksctl get cluster --name $EKS_CLUSTER_NAME -o json | jq '.[0].Status' | sed 's/"//g')
    echo "cluster exists and in ${STATUS} state. checking if the updates are available"
    eksctl update cluster --name=$EKS_CLUSTER_NAME

    OLD_NODEGROUP_NAME=$(eksctl get nodegroups --cluster=$EKS_CLUSTER_NAME -o json | jq '.[0].Name' | sed 's/"//g')
    eksctl create nodegroup \
    --cluster $EKS_CLUSTER_NAME \
    --nodes-min $NODE_MIN \
    --nodes-max $NODE_MAX \
    --node-volume-size $NODE_VOLUME_SIZE \
    --node-type $NODE_SIZE \
    --managed --ssh-access \
    --ssh-public-key $SSK_PUBLIC_KEY \
    --name $NODEGROUP_NAME \
    --wait

    eksctl delete nodegroup \
    --cluster=$EKS_CLUSTER_NAME \
    --name=$OLD_NODEGROUP_NAME \
    --wait

    eksctl utils update-kube-proxy
    eksctl utils update-aws-node
    eksctl utils update-coredns
else
    eksctl create cluster \
    --name $EKS_CLUSTER_NAME \
    --region $AWS_REGION \
    --nodegroup-name $NODEGROUP_NAME \
    --node-type $NODE_SIZE \
    --nodes 3 \
    --nodes-min $NODE_MIN \
    --nodes-max $NODE_MAX \
    --ssh-access \
    --ssh-public-key $SSK_PUBLIC_KEY \
    --managed \
    --wait
fi

# bash /home/evex/workspace/eks/helm/cert-manager/cert-manager

aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
kubectl create ns mgmt
kubectl config set-context --current --namespace=mgmt

helm repo add stable https://kubernetes-charts.storage.googleapis.com

#nginx-ingress controller
helm upgrade --install --force nginx-ingress stable/nginx-ingress --namespace kube-system

#metrics server
helm upgrade --install --force metrics-server stable/metrics-server --namespace kube-system

#certmanager
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.13/deploy/manifests/00-crds.yaml
helm repo add jetstack https://charts.jetstack.io
kubectl create namespace cert-manager
helm upgrade --install --force cert-manager jetstack/cert-manager --namespace cert-manager 

#elastic stack
helm upgrade --install --force \
-f /home/evex/workspace/eks/helm/elastic-stack/elastic-stack.yaml \
elastic-stack \
stable/elastic-stack \
--namespace kube-system

#weave-scope
helm upgrade --install --force weave-scope stable/weave-scope --namespace mgmt

if [[ "$EKS_CLUSTER_NAME" == "dev" ]]
then
    #jenkins
    helm upgrade --install --force -f /home/evex/workspace/eks/helm/jenkins/jenkins.yaml jenkins stable/jenkins --namespace kube-system
    
    #sonarqube
    helm upgrade --install --force -f /home/evex/workspace/eks/helm/sonarqube/sonarqube.yaml sonarqube stable/sonarqube --namespace mgmt
fi

#grafana
helm upgrade --install --force -f /home/evex/workspace/eks/helm/grafana/values.yaml grafana stable/grafana --namespace kube-system

#prometheus
helm upgrade --install --force prometheus stable/prometheus --namespace kube-system

