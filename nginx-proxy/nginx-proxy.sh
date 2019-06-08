#!/bin/bash

usage() {
  echo -e "Usage: $0 --cmd create --kubeconfig <path/to/kubeconfig> [--elasticsearch <on|off> --elasticsearch-stack <elasticsearch-stack-name>] [--prometheus <on|off>] [--grafana <on|off>] [--alertmanager <on|off>]"
  echo -e "Usage: $0 --cmd delete --kubeconfig <path/to/kubeconfig>"
  exit 1
}

create_proxy() {
  PASSWORD=$(openssl rand -hex 12)
  CREDENTIALS=$(htpasswd -n -b admin $PASSWORD)
  echo "Credentials for Nginx proxy:"
  echo "  - login: admin"
  echo "  - password: $PASSWORD"

  ES_STACK_NAME=$1
  ELASTICSEARCH=$2
  PROMETHEUS=$3
  GRAFANA=$4
  ALERTMANAGER=$5
  KUBE_CONFIG=$6

  CMD=""

  if [ "$ELASTICSEARCH" == "on" ]; then
    eval "cat ./elasticsearch.yaml | sed 's/{STACKNAME}/$ES_STACK_NAME/g' | kubectl apply --kubeconfig $KUBE_CONFIG -f -"
    CMD="$CMD | sed 's/#E //g'"
  fi

  if [ "$PROMETHEUS" == "on" ]; then
    kubectl apply --kubeconfig $KUBE_CONFIG -f prometheus.yaml
    CMD="$CMD | sed 's/#P //g'"
  fi

  if [ "$GRAFANA" == "on" ]; then
    kubectl apply --kubeconfig $KUBE_CONFIG -f grafana.yaml
    CMD="$CMD | sed 's/#G //g'"
  fi

  if [ "$ALERTMANAGER" == "on" ]; then
    kubectl apply --kubeconfig $KUBE_CONFIG -f alertmanager.yaml
    CMD="$CMD | sed 's/#A //g'"
  fi

  echo "$CREDENTIALS" > ./htpasswd
  kubectl create configmap nginxpwd --from-file=./htpasswd
  rm -f ./htpasswd
  eval "cat ./nginx-proxy.yaml $CMD | kubectl apply --kubeconfig $KUBE_CONFIG -f -"
}

delete_proxy() {
  kubectl delete configmap nginxelasticsearch --kubeconfig=$1
  kubectl delete configmap nginxprometheus --kubeconfig=$1
  kubectl delete configmap nginxgrafana --kubeconfig=$1
  kubectl delete configmap nginxalertmanager --kubeconfig=$1
  kubectl delete configmap nginxpwd --kubeconfig=$1
  kubectl delete configmap nginxconf --kubeconfig=$1
  kubectl delete service/nginx-proxy --kubeconfig=$1
  kubectl delete replicationcontroller/nginx-controller --kubeconfig=$1
}

ELASTICSEARCH_STACK_NAME="none"
ELASTICSEARCH="off"
PROMETHEUS="off"
GRAFANA="off"
ALERTMANAGER="off"

while [ "$1" != "" ]; do
    case "$1" in
        -es|--elasticsearch-stack)
            ELASTICSEARCH_STACK_NAME=$2
            shift 2 ;;
        -e|--elasticsearch)
            ELASTICSEARCH=$2
            shift 2 ;;
        -p|--prometheus)
            PROMETHEUS=$2
            shift 2 ;;
        -g|--grafana)
            GRAFANA=$2
            shift 2 ;;
        -g|--alertmanager)
            ALERTMANAGER=$2
            shift 2 ;;
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

export CURRENT_CONTEXT=$(kubectl config view -o jsonpath='{.current-context}')
export USER_NAME=$(kubectl config view -o jsonpath='{.contexts[?(@.name == "'"${CURRENT_CONTEXT}"'")].context.user}')
export CLUSTER_NAME=$(kubectl config view -o jsonpath='{.contexts[?(@.name == "'"${CURRENT_CONTEXT}"'")].context.cluster}')
kubectl config set-context spark --cluster=${CLUSTER_NAME} --user=${USER_NAME} --kubeconfig=$1
kubectl config use-context spark --kubeconfig=$1

case "$CMD" in
  create)
    create_proxy ${ELASTICSEARCH_STACK_NAME} ${ELASTICSEARCH} ${PROMETHEUS} ${GRAFANA} ${ALERTMANAGER} ${KUBE_CONFIG}
    ;;
  delete)
    delete_proxy ${KUBE_CONFIG}
    ;;
  *)
    usage
    ;;
esac
