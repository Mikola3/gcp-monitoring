SHELL = /bin/bash

KUBE_CONFIG?=$(HOME)/.kube/config
#SLACK_CHANNEL?=https://hooks.slack.com/services/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

lint: prometheus/*.yaml nginx-proxy/*.yaml spark/*.yaml *.yaml grafana/*.yaml alertmanager/*.yaml
	# yaml lint
	yamllint -d "{extends: relaxed, rules: {line-length: {max: 1024}, indentation: {spaces: 2, indent-sequences: false}}}" $^

create-pv-pvc:
	bash create-pv-pvc.sh

create-nginx:
#Deploy Nginx proxy this step is optional and needed only if you want to access Prometheus, Grafana or Alertmanager from the Internet), the credentials to access the endpoint will be printed on the screen
	cd ./nginx-proxy && ././nginx-proxy.sh --cmd create --kubeconfig $(KUBE_CONFIG) --elasticsearch off --prometheus on --grafana on --alertmanager on

delete-nginx:
# Delete nginx
	cd ./nginx-proxy && ././nginx-proxy.sh --cmd delete --kubeconfig $(KUBE_CONFIG)

create-prometheus:
# Deploy prometheus
	cd ./prometheus && ./manage.sh --cmd create --kubeconfig $(KUBE_CONFIG)

delete-prometheus:
# Delete prometheus
	cd ./prometheus && ./manage.sh --cmd delete --kubeconfig $(KUBE_CONFIG)

create-grafana:
# Deploy grafana
	bash grafana/manage.sh --cmd create --kubeconfig $(KUBE_CONFIG)

delete-grafana:
# Delete grafana
	bash grafana/manage.sh --cmd delete --kubeconfig $(KUBE_CONFIG)

create-prometheus-grafana: create-prometheus create-grafana

delete-prometheus-grafana: delete-grafana delete-prometheus

create-alertmanager:
# Deploy alertmanager
	bash alertmanager/manage.sh --cmd create --kubeconfig $(KUBE_CONFIG)

delete-alertmanager:
# Delete alertmanager
	bash alertmanager/manage.sh --cmd delete --kubeconfig $(KUBE_CONFIG)

create-prometheus-alertmanager: create-prometheus create-alertmanager

delete-prometheus-alertmanager: delete-prometheus delete-alertmanager

create-prometheus-alertmanager-grafana: create-prometheus create-alertmanager create-grafana

delete-prometheus-alertmanager-grafana: delete-prometheus delete-alertmanager delete-grafana

create-monitoring: create-prometheus-alertmanager-grafana create-nginx

delete-monitoring: delete-nginx delete-prometheus-alertmanager-grafana

.PHONY: lint create-nginx create-prometheus delete-prometheus create-grafana delete-grafana create-prometheus-grafana delete-prometheus-grafana create-alertmanager delete-alertmanager create-prometheus-alertmanager delete-prometheus-alertmanager create-prometheus-alertmanager-grafana delete-prometheus-alertmanager-grafana create-monitoring
