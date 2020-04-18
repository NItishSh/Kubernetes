#!/bin/bash

DIR=$(dirname "$0")

AWS_REGION="ap-south-1"
EKS_CLUSTER_NAME="dev"
SSK_PUBLIC_KEY="/home/evex/.ssh/eks-key-pair.pub"
NODEGROUP_NAME="standard-workers-$(date +%d-%m-%Y)"
NODE_MIN="1"
NODE_MAX="15"
NODE_VOLUME_SIZE="20"
NODE_SIZE="t3.large"


#aws cli
#https://docs.aws.amazon.com/cli/latest/userguide/install-linux.html
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py --user
echo "export PATH=~/.local/bin:$PATH" >> ~/.bash_profile
source ~/.bash_profile
pip install awscli --upgrade --user

#upgrade kubectl
#https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/darwin/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

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

export KUBECONFIG=~/.kube/clusters/$EKS_CLUSTER_NAME.config
aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
kubectl create ns mgmt # start using kube-system
kubectl config set-context --current --namespace=mgmt

#ecr login for docker registry
kubectl apply -f $DIR/../jenkins/docker-config.yaml

helm repo add stable https://kubernetes-charts.storage.googleapis.com

#efs-provisioner
helm upgrade --install --force efs-provisioner stable/efs-provisioner \
--set efsProvisioner.efsFileSystemId=fs-a7973076 --set efsProvisioner.awsRegion=$AWS_REGION

#nginx-ingress controller
helm upgrade --install --force nginx-ingress stable/nginx-ingress \
--set controller.publishService.enabled=true

#metrics server
helm upgrade --install --force metrics-server stable/metrics-server

#certmanager
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.13/deploy/manifests/00-crds.yaml
helm repo add jetstack https://charts.jetstack.io
kubectl create namespace cert-manager
helm upgrade --install --force cert-manager jetstack/cert-manager --namespace cert-manager 
kubectl apply -f $DIR/helm/cert-manager/clusterissuer.yaml

#elastic stack
helm upgrade --install --force elastic-stack stable/elastic-stack \
-f $DIR/helm/elastic-stack/elastic-stack.yaml 

#weave-scope
helm upgrade --install --force weave-scope stable/weave-scope

if [[ "$EKS_CLUSTER_NAME" == "dev" ]]
then
    #jenkins
    helm upgrade --install --force -f $DIR/helm/jenkins/jenkins.yaml jenkins stable/jenkins
    
    #sonarqube
    helm upgrade --install --force -f $DIR/helm/sonarqube/sonarqube.yaml sonarqube stable/sonarqube
fi

#grafana
helm upgrade --install --force -f $DIR/helm/grafana/values.yaml grafana stable/grafana

#prometheus
helm upgrade --install --force prometheus stable/prometheus

