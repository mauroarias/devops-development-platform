#!/bin/bash

source ../commonLibs.sh
source ../configFile.sh

cpu=8
mem=10240
kubernetesVersion=v1.20.2
#ACTIVATE or DEACTIVATE
kvmOn=$ACTIVATE

if [ $kvmOn = $ACTIVATE ]
then
    driver="--driver kvm2"
fi


#****************************************

printMessage "stopping and deleting existing minikube instances"
minikube delete

printMessage "starting minikube with $cpu cpus, $mem ram and KVM $kvmOn"
minikube start --memory $mem --cpus $cpu --kubernetes-version=$kubernetesVersion $driver || exitOnError "Error starting minikube"

printMessage "stopping minikube"
minikube stop

echo "${green}minikube done... you are good!"
