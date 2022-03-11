#!/bin/bash

source ../commonLibs.sh

minikube=$1

if [ $# -eq 0 ]
then
	echo "Are you using minikube YES || NO"
	read var
	if [ $var = "YES" ]
	then
		minikube=$ACTIVATE
	fi
fi

if [ $minikube = $ACTIVATE ]
then
	printMessage "starting minikube"
	minikube start || exitOnError "Error starting minikube"
fi

printMessage "deleting istios namespaces"
kubectl "delete ns istio-system"
kubectl "delete ns istio-ingress"

printMessage "installing & updating istio helm repo"
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

printMessage "creating system-istio namespace"
kubectl "create namespace istio-system"

printMessage "installing istio base and istiod"
echo "--------------------"
helm install istio-base istio/base -n istio-system --debug
echo "--------------------"
helm install istiod istio/istiod -n istio-system --debug --wait || exitOnError "error installing istio-system"
echo "--------------------"

printMessage "installing igestion gateway"
kubectl "create namespace istio-ingress"
kubectl "label namespace istio-ingress istio-injection=enabled"
echo "--------------------"
helm install istio-ingress istio/gateway -n istio-ingress --debug --wait || exitOnError "error installing istio-ingress"
echo "--------------------"

helm status istiod -n istio-system


if [ $minikube = $ACTIVATE ]
then
	printMessage "stopping minikube"
	minikube stop
fi

echo "${green}istio done... you are good!"