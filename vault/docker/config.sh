#!/bin/bash

SEAL_CONFIG_FILE=/vault/unseal/vault.keys

autoUnseal () {
    echo "unsealing server"
	for i in $(cat $SEAL_CONFIG_FILE | grep "Unseal Key" | awk '{print $4}')
	do 
		vault operator unseal $i
	done 
}

sleep 3
export VAULT_ADDR='http://127.0.0.1:8200'
if [ -f "$SEAL_CONFIG_FILE" ];
then
    autoUnseal
else
    echo "Booting firts time, configure vault & set tokens"
    vault operator init -key-shares=6 -key-threshold=3 > $SEAL_CONFIG_FILE

    autoUnseal
fi