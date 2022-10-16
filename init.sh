#!/bin/bash

source ./commonLibs.sh

source ./configFile.sh

#****************************************

#vault
printTitleWithColor "initialising Vault" "${orange}"
cd ./vault
source ./initVault.sh

#minikube
if [ $minikubeOn = $ACTIVATE ]
then
	printTitleWithColor "initialising minikube" "${orange}"
	cd ../minikube
	source ./initMinikube.sh
fi

#registry
if [ $registry = $LOCAL_REGISTRY ]
then
	printTitleWithColor "initialising registry" "${orange}"
	cd ../registry
	source ./initRegistry.sh
	cd ..
	registryUser=
	registryPassword=
elif [ $registry = $JFOG_REGISTRY ]
then
	printTitleWithColor "Jfrog registry configured" "${orange}"
	registryUser=$JFROG_USER
	registryPassword=$JFROG_PASSWORD
fi

#CI
if [ $ci = $JENKINS_CI ]
then
	#Jenkins
	printTitleWithColor "initialising Jenkins" "${orange}"
	cd ../jenkins
	source ./initJenkins.sh
#elif [ $ci = $CONCOURSE_CI ]
#then
#	printTitleWithColor "initialising concourse" "${orange}"
#	cd ../concourse
#	source ./initConcourse.sh	
fi

#Istio
if [ $istioOn = $ACTIVATE ]
then
	printTitleWithColor "initialising istio" "${orange}"
	cd ../istio
	source ./initIstio.sh $minikubeOn
fi

#sonar
printTitleWithColor "initialising sonarqube" "${orange}"
cd ../sonar
source ./initSonar.sh

cd ..
echo "${green}init done... you are good!"