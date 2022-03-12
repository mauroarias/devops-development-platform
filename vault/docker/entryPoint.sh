#!/bin/bash

CONFIG_FILE=/vault/config/vault.json

echo "starting vault server"
sh /config.sh &
vault server -config=$CONFIG_FILE
sleep 2
