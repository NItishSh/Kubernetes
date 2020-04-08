#!/bin/bash
set -x

helm template metrics-server stable/metrics-server --namespace kube-system | kubectl delete -f -
kubectl delete sa metrics-server -n kube-system
kubectl delete svc metrics-server -n kube-system
kubectl delete deploy metrics-server -n kube-system
helm uninstall metrics-server --namespace kube-system
helm upgrade --install --force metrics-server stable/metrics-server --namespace kube-system
#helm upgrade --install --force -f values.yaml metrics-server stable/metrics-server --namespace kube-system
sleep 5
kubectl get apiservices v1beta1.metrics.k8s.io -n kube-system
kubectl describe apiservices v1beta1.metrics.k8s.io -n kube-system
kubectl get pods -l app=metrics-server -n kube-system
kubectl logs -l app=metrics-server -f -n kube-system

#KUBE_EDITOR="nano" kubectl edit deploy metrics-server -n kube-system
#- --kubelet-preferred-address-types=InternalIP

