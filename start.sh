#!/bin/bash

source ./commonLibs.sh

source ./configFile.sh

printMessage "preparing docker compose file"
echo -e "version: '3.3' \nservices:" > docker-compose.template
tail -n +3 ./jenkins/docker-compose.template >> docker-compose.template
echo "     - SONAR_USER=$SONAR_USER" >>  docker-compose.template
echo "     - SONAR_PASSWORD=$SONAR_PASSWORD" >>  docker-compose.template
echo "" >> docker-compose.template
tail -n +3 ./vault/docker-compose.yml >> docker-compose.template
echo -e "\n" >> docker-compose.template
tail -n +3 ./sonar/docker-compose.yml >> docker-compose.template
echo -e "\n" >> docker-compose.template
tail -n +3 ./registry/docker-compose.yml >> docker-compose.template

parseJenkins
cat docker-compose.template | sed 's!../volumes!./volumes!g' | envsubst '${docker_path} ${maven_path} ${GIT_HUB_TOKEN} ${GIT_HUB_USER} ${GIT_HUB_ORGANIZATION} ${GIT_EMAIL} ${GIT_USER} ${BITBUCKET_PASSWD} ${BITBUCKET_USER}'  > docker-compose.yml

printMessage "stating Jenkins & wait for to be available"
docker-compose up -d
sleep 5

autoUnseal "volumes"

#minikube
if [ $minikubeOn = $ACTIVATE ]
then
	minikube start
fi

cd ..
echo "${green}started done... you are good!"