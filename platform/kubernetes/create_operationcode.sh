#!/usr/bin/env bash

#set -euf -o pipefail

# This is a quick hacky script to standup operationcode.org on kubernetes
# If run by itself it will standup all apps. Alternatively you can provide
# it with one or more app names to install

KUBECTL=$(which kubectl)
HELM=$(which helm)

function create_service_and_deployment(){
  $KUBECTL create -f deployment.yml
  $KUBECTL create -f service.yml
}

# This function assumes you have the required secrets for an app
# defined as env vars at ${app_name}_secret.sh
function create_secrets_for(){
  app_name=$1
  cd secrets
  . ~/bin/${app_name}_secrets.sh
  ./create_secrets.sh
  $KUBECTL create -f secret.yml
  cd ..
}

# Create namespace
echo $KUBECTL create -f operationcode-namespace.yml

if [[ $* ]]; then
  apps=$*
else
  apps=$(find . -type d -depth 1)
fi

for app in $apps; do
  app_name=$(basename $app)
  echo "Standing up $app_name"
  cd $app_name

  create_service_and_deployment
  if [[ -d "secrets" ]]; then
    create_secrets_for $app_name
  fi

  cd ..
done

exit 0

# Helm is a kubernetes package manager
# You can get a list of apps here: https://kubeapps.com/
$HELM init

## Backend Postgresql
$HELM install --name operationcode-psql stable/postgresql --set postgresPassword=$POSTGRES_PASSWORD

## Backend Redis
$HELM install --name operationcode-redis stable/redis --set usePassword=false
