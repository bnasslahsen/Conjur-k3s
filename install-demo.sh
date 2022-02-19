#!/bin/bash

kubectl create ns testapp

#helm list --all-namespaces
#helm delete cluster-prep -n  cyberark-conjur
helm install cluster-prep cyberark/conjur-config-cluster-prep \
  --namespace cyberark-conjur \
  --create-namespace \
  --set conjur.account="devops-org" \
  --set conjur.applianceUrl="https://host-1" \
  --set conjur.certificateBase64="$(base64 -w0 /home/devops/Conjur-K3s/conjur-devops-org.pem)" \
  --set authnK8s.authenticatorID="dev" \
  --set authnK8s.serviceAccount.name="authn-k8s-sa"

#helm delete namespace-prep -n testapp
helm install namespace-prep cyberark/conjur-config-namespace-prep   --namespace testapp   --set authnK8s.goldenConfigMap="conjur-configmap"   --set authnK8s.namespace="cyberark-conjur"

#Conjur cli
export conjur="docker run --rm -it --add-host host-1:10.0.0.1 -v $(pwd):/root cyberark/conjur-cli:5"
bash -c "yes yes | $conjur init --url https://host-1 --account devops-org"

$conjur policy load root root/policies/policy_for_human_users.yml
$conjur policy load root root/policies/policy_for_authenticator_identities.yml
$conjur policy load root root/policies/policy_for_k8s_authenticator_service.yml

source conjur/02_initialize_ca.sh

export TOKEN_SECRET_NAME="$(kubectl get secrets -n cyberark-conjur | grep 'authn-k8s-sa.*service-account-token' | head -n1 | awk '{print $1}')"
export SA_TOKEN="$(kubectl get secret $TOKEN_SECRET_NAME -n cyberark-conjur --output='go-template={{ .data.token }}' | base64 -d)"
export K8S_API_URL=https://10.0.0.3:6443
export K8S_CA_CERT="$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 -d)"

$conjur variable values add conjur/authn-k8s/dev/kubernetes/service-account-token "$SA_TOKEN"
$conjur variable values add conjur/authn-k8s/dev/kubernetes/ca-cert "$K8S_CA_CERT"
$conjur variable values add conjur/authn-k8s/dev/kubernetes/api-url "$K8S_API_URL"

# Already done

$conjur policy load root root/policies/testapp-policy.yml

$conjur variable values add app/testapp/secret/password "5b3e5f75cb3cdc725fe40318"
$conjur variable values add app/testapp/secret/username "test_app"
$conjur variable values add app/testapp/secret/host "testapp-db.testapp.svc.cluster.local"
$conjur variable values add app/testapp/secret/port "5432"
$conjur policy load root root/policies/app-policy.yml


kubectl apply -f app/01_db.yml
kubectl -n testapp create configmap secretless-config --from-file=./secretless/secretless.yml
kubectl -n testapp create configmap conjur-cert --from-file=ssl-certificate="/home/devops/Conjur-K3s/conjur-devops-org.pem"

# deploy
kubectl apply -f app/02_pet-store.yml

#checks
export URL=$(kubectl describe  service testapp-secure -n=testapp |grep Endpoints | awk '{print $2}' )

echo $URL
#curl -d "{\"name\": \"my-pet\"}" -H "Content-Type: application/json" $URL/pet
#curl $URL/pet/1

