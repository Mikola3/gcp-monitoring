#!/bin/bash

usage() {
  echo -e "Usage: $0 --cmd create --kubeconfig <path/to/kubeconfig>"
  echo -e "Usage: $0 --cmd delete --kubeconfig <path/to/kubeconfig>"
  exit 1
}

create() {
  kubectl create namespace monitoring --kubeconfig=$1
  #kubectl apply -f prometheus-pv-pvc.yaml -n monitoring --kubeconfig=$1
  kubectl apply -f clusterRole.yaml --kubeconfig=$1
  kubectl apply -f config-map.yaml -n monitoring --kubeconfig=$1
  kubectl apply -f prometheus-deployment.yaml --namespace=monitoring --kubeconfig=$1
  kubectl rollout status deployment prometheus-deployment -n monitoring --kubeconfig=$1
  kubectl apply -f prometheus-service.yaml --namespace=monitoring --kubeconfig=$1
}

delete() {
  kubectl delete service prometheus -n monitoring --kubeconfig=$1
  kubectl delete deployment prometheus-deployment -n monitoring --kubeconfig=$1
  kubectl delete configmap prometheus-server-conf -n monitoring --kubeconfig=$1
  #kubectl delete -f prometheus-pv-pvc.yaml -n monitoring --kubeconfig=$1
  kubectl delete namespace monitoring --kubeconfig=$1
  kubectl delete clusterroles.rbac.authorization.k8s.io "prometheus" --kubeconfig=$1
  kubectl delete clusterrolebindings.rbac.authorization.k8s.io "prometheus" --kubeconfig=$1
}

while [ "$1" != "" ]; do
    case "$1" in
        -c|--cmd)
            CMD=$2
            shift 2 ;;
        -k|--kubeconfig)
            KUBE_CONFIG=$2
            shift 2 ;;
        -h|--help)
            usage ;;
        --) shift ; echo "break" ; break ;;
        *)
            echo "Invalid argument [${1}]"
            usage
            ;;
    esac
done

case "$CMD" in
  create)
    create ${KUBE_CONFIG}
    ;;
  delete)
    delete ${KUBE_CONFIG}
    ;;
  *)
    usage
    ;;
esac
