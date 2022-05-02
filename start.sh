#!/bin/bash

source ./commonLibs.sh

source ./configFile.sh

printMessage "preparing docker compose file"
echo -e "version: '3.3' \nservices:" > docker-compose.template
tail -n +3 ./jenkins/docker-compose.template >> docker-compose.template
echo '' >> docker-compose.template
tail -n +3 ./vault/docker-compose.yml >> docker-compose.template
echo '' >> docker-compose.template
tail -n +3 ./sonar/docker-compose.yml >> docker-compose.template
echo '' >> docker-compose.template
tail -n +3 ./registry/docker-compose.yml >> docker-compose.template

parseJenkins
cat docker-compose.template | sed 's!../volumes!./volumes!g' | envsubst '${docker_path} ${maven_path}'  > docker-compose.yml

printMessage "stating Jenkins & wait for to be available"
docker-compose up -d
sleep 5

#minikube
if [ $minikubeOn = $ACTIVATE ]
then
	minikube start
fi

rm jenkins-cli.*
downloadJenkinsCli
waitSonarQubeUp
traceOff
tokenName=$(curl -X GET -H 'Content-Type: application/json' -u "$SONAR_USER:$SONAR_PASSWORD" 'http://localhost:9000/api/user_tokens/search' | jq -r '.userTokens[] | select(.name == "token") | .name')
if [ "$tokenName" != "token" ]
then
	echo "regenerating token"
	token=$(curl -X POST -H 'Content-Type: application/json' -u "$SONAR_USER:$SONAR_PASSWORD" 'http://localhost:9000/api/user_tokens/generate?name=token' | jq -r '.token')
	createTextCred 'sonar-token' $token './jenkins/'
fi
traceOn

cd ..
echo "${green}started done... you are good!"