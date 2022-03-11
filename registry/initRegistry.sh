#!/bin/bash

source ../commonLibs.sh

#****************************************

printAlert "BE SURE THAT YOUR REGISTRY IMAGE WAS STOPPED..."

printMessage "stating Jenkins & wait for to be available"
docker-compose up -d

docker-compose down

echo "${green}Registry done... you are good!"