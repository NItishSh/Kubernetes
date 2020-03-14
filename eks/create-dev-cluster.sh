#!/bin/bash

eksctl create cluster \
--name dev \
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
#eksctl create nodegroup --cluster dev --nodes-min 1 --nodes-max 10 --node-volume-size 20 --node-type t3.medium --managed --ssh-access --ssh-public-key /home/evex/.ssh/eks-key-pair.pub --name standard-workers
bash /home/evex/workspace/eks/helm/cert-manager/cert-manager
