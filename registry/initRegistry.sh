#!/bin/bash

source ../commonLibs.sh

#****************************************

printAlert "BE SURE THAT YOUR REGISTRY IMAGE WAS STOPPED..."

printMessage "stating registry & wait for to be available"
docker-compose down >> /dev/null

docker-compose up -d

echo "${green}Registry done... you are good!"