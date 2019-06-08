#!/bin/bash
set -x
gcloud beta filestore instances create nfshackathon --zone=europe-west3-a --tier=STANDARD --file-share=name="nfshackathon",capacity=1Tb --network=name="default" --project="or2-msq-epmc-acm-h09-t1iylu"
NFS_IP=$(gcloud beta filestore instances list | grep nfshackathon | awk '{print $6}')
CONFIG="sed 's#server:.*#server: $NFS_IP#g'"
kubectl create ns monitoring
eval "cat pv-pvc.yaml | $CONFIG | kubectl apply -f - -n monitoring"