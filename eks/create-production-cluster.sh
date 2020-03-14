#!/bin/bash

eksctl create cluster \
--name production \
--version 1.14 \
--region ap-south-1 \
--nodegroup-name standard-workers \
--node-type t3.medium \
--nodes 3 \
--nodes-min 1 \
--nodes-max 10 \
--ssh-access \
--ssh-public-key /home/evex/.ssh/eks-key-pair.pub \
--managed
#eksctl create nodegroup --cluster qa --nodes-min 1 --nodes-max 10 --node-volume-size 20 --node-type t3.medium --managed --ssh-access --ssh-public-key /home/evex/.ssh/eks-key-pair.pub --name standard-workers
bash /home/evex/workspace/eks/helm/cert-manager/cert-manager
bash /home/evex/workspace/eks/helm/metrics-server/metrics-server
bash /home/evex/workspace/eks/helm/nginx-ingress/nginx-ingress
bash /home/evex/workspace/eks/helm/elastic-stack/elastic-stack

bash /home/evex/workspace/eks/helm/prometheus/prometheus
bash /home/evex/workspace/eks/helm/grafana/grafana

bash /home/evex/workspace/eks/helm/efs-provisioner/efs-provisioner
# bash /home/evex/workspace/eks/helm/sonarqube/sonarqube
# kubectl apply -f /home/evex/workspace/eks/helm/sonarqube/sonarqube-ingress.yaml
# bash /home/evex/workspace/eks/helm/jenkins/jenkins
# kubectl apply -f /home/evex/workspace/eks/helm/jenkins/jenkins-ingress.yaml
