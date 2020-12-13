#!/bin/bash

# assumes that keyless ssh has been enabled for root

if false; then
ssh root@k3s1 'curl -sfL https://get.k3s.io | sh -s - --disable=traefik --docker --resolve-conf ""'
TOKEN=$(ssh root@k3s1 'cat /var/lib/rancher/k3s/server/token')

# clustertools node
ssh root@k3s2 "curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN K3S_URL=https://k3s1:6443 sh -s - --node-label nodegroup-role=clustertools  --docker"

# jhcontrolplane node
ssh root@k3s3 "curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN K3S_URL=https://k3s1:6443 sh -s - --docker --node-label nodegroup-role=jhcontrolplane --node-label hub.jupyter.org/node-purpose=core"

# jhusers
ssh root@k3s-worker1 "curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN K3S_URL=https://k3s1:6443 sh -s - --docker --node-label nodegroup-role=jhusers --node-label hub.jupyter.org/node-purpose=user --node-taint hub.jupyter.org/dedicated=user:NoSchedule"
ssh root@k3s-worker2 "curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN K3S_URL=https://k3s1:6443 sh -s - --docker --node-label nodegroup-role=jhusers --node-label hub.jupyter.org/node-purpose=user --node-taint hub.jupyter.org/dedicated=user:NoSchedule"

# install helm 
ssh root@k3s1 'curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash'
# and helm plugin
ssh root@k3s1 'helm plugin install https://github.com/oneilsh/helm-kush.git'

# install longhorn - disabling for now since it requires getting the KUBECONFIG variable set correctly for each command
#ssh root@k3s1 'helm repo add longhorn https://charts.longhorn.io'
#ssh root@k3s1 'helm repo update'
#ssh root@k3s1 'kubectl create namespace longhorn-system'
#ssh root@k3s1 'helm install longhorn longhorn/longhorn --namespace longhorn-system'

# setup ingress for longhorn UI - not sure why it's not asking for login? (this won't work til ingress controller is installed)
#ssh root@k3s1 'USER=admin; PASSWORD=submarine; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth'
#ssh root@k3s1 'kubectl -n longhorn-system create secret generic basic-auth --from-file=auth'
#ssh root@k3s1 'kubectl apply -n longhorn-system -f longhorn_ingress.yaml'

# and make local path not a default storageclass
# ssh root@k3s1 'kubectl patch storageclass local-path -p \'{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}\''
fi

# get nfs ready 
for NODE in k3s1 k3s2 k3s3 k3s-worker1 k3s-worker2; do
  ssh root@$NODE 'apt-get install -y nfs-kernel-server'
  ssh root@$NODE 'systemctl stop nfs-kernel-server'
  ssh root@$NODE 'systemctl disable nfs-kernel-server'
  ssh root@$NODE 'modprobe nfs'
  ssh root@$NODE 'modprobe nfsd'
done
