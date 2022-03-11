#!/bin/bash

source ../commonLibs.sh

#****************************************

printAlert "BE SURE THAT YOUR VAULT IMAGE WAS STOPPED..."

printMessage "creating folder structure and clean up"
mkdir -p ../volumes/vault/{config,file,logs}
sudo rm -rf ../volumes/vault/config/*
sudo rm -rf ../volumes/vault/file/*

printMessage "cretaing config"
cat > ../volumes/vault/config/vault.json << EOF
{
  "backend": {
    "file": {
      "path": "/vault/file"
    }
  },
  "listener": {
    "tcp":{
      "address": "0.0.0.0:8200",
      "tls_disable": 1
    }
  },
  "ui": true
}
EOF

printMessage "stating vault & wait for to be available"
docker-compose up -d
sleep 2

printMessage "configure vault & set tokens "
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init -key-shares=6 -key-threshold=3 > vault.config
for i in $(cat vault.config | grep "Unseal Key" | awk '{print $4}')
do 
    vault operator unseal $i
done 
vault status -format=json
vault login $(cat vault.config | grep "Initial Root Token: " | awk '{print $4}')

printMessage "cleaning files"
rm vault.config

printMessage "Enable the secret kv engine"
vault secrets enable -version=1 -path=secret kv

docker-compose down

echo "${green}vault done... you are good!"
