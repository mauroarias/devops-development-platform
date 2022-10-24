#!/bin/bash

source ../commonLibs.sh
source ../configFile.sh

#****************************************

printAlert "BE SURE THAT YOUR VAULT IMAGE WAS STOPPED..."

printMessage "creating folder structure and clean up"
sudo rm -rf ../volumes/vault/*
mkdir -p ../volumes/vault/{config,file,logs,unseal}

printMessage "Config"
cp config/vault.json ../volumes/vault/config/vault.json

printMessage "building docker image"
docker build --no-cache -t vault:local . || exitOnError "error building image"

printMessage "stating vault & wait for to be available"
docker-compose up -d
waitServerUp "http://localhost:8200/v1/sys/health" "Vault" 20

printMessage "Authenticating..."
vault status -format=json
vault login $(cat ../volumes/vault/unseal/vault.keys | grep "Initial Root Token: " | awk '{print $4}')

printMessage "Enable the secret kv engine"

export VAULT_ADDR='http://127.0.0.1:8200'
vault secrets enable -version=1 -path=secret kv

printMessage "Adding user & policy"
cat config/admin-policy.hcl | vault policy write my-policy -
vault auth enable userpass
vault token create -format=json -policy=my-policy
vault write auth/userpass/users/$VAULT_USER password=$VAULT_PASSWORD policies=my-policy

vault kv put secret/infra/git email=$GIT_EMAIL user=$GIT_USER
vault kv put secret/infra/gitHub token=$GIT_HUB_TOKEN user=$GIT_HUB_USER oganization=$GIT_HUB_ORGANIZATION
vault kv put secret/infra/bitbucket password=$BITBUCKET_PASSWD user=$BITBUCKET_USER
vault kv put secret/infra/sonar password=$SONAR_PASSWORD user=$SONAR_USER

docker-compose down

echo "${green}vault done... you are good!"