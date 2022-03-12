#!/bin/bash

source ../commonLibs.sh

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
sleep 3

printMessage "Authenticating..."
vault status -format=json
vault login $(cat ../volumes/vault/unseal/vault.keys | grep "Initial Root Token: " | awk '{print $4}')

printMessage "Enable the secret kv engine"
export VAULT_ADDR='http://127.0.0.1:8200'
vault secrets enable -version=1 -path=secret kv

docker-compose down

echo "${green}vault done... you are good!"
