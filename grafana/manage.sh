#!/bin/bash

usage() {
  echo -e "Usage: $0 --cmd create --kubeconfig <path/to/kubeconfig>"
  echo -e "Usage: $0 --cmd delete --kubeconfig <path/to/kubeconfig>"
  exit 1
}

create() {
  kubectl apply -f grafana/grafana-namespace.yaml
  #kubectl apply -f grafana/grafana-pv-pvc.yaml -n monitoring --kubeconfig=$1
  kubectl apply -f grafana/grafana-configmap.yaml -n monitoring --kubeconfig=$1
  kubectl apply -f grafana/grafana-deployment.yaml -n monitoring --kubeconfig=$1
  kubectl rollout status deployment grafana-deployment -n monitoring --kubeconfig=$1
  kubectl apply -f grafana/grafana-service.yaml -n monitoring --kubeconfig=$1
}

delete() {
  kubectl delete configmap grafana-config -n monitoring --kubeconfig=$1
  kubectl delete service grafana-service -n monitoring --kubeconfig=$1
  kubectl delete deployment grafana-deployment -n monitoring --kubeconfig=$1
  #kubectl delete -f grafana/grafana-pv-pvc.yaml -n monitoring --kubeconfig=$1
  kubectl delete namespace monitoring --kubeconfig=$1
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
