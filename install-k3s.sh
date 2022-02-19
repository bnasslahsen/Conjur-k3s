#!/bin/bash

/usr/local/bin/k3s-killall.sh
/usr/local/bin/k3s-uninstall.sh

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

cp /etc/rancher/k3s/k3s.yaml /home/devops/.config
export KUBECONFIG=/home/devops/.config/k3s.yaml
