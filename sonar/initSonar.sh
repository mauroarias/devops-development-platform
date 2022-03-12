#!/bin/bash

source ../commonLibs.sh

source ../configFile.sh

#****************************************

MAX_WAIT_SEC=60

printAlert "BE SURE THAT YOUR SONAR IMAGE WAS STOPPED..."

printMessage "creating folder structure and clean up"
sudo rm -rf ../volumes/sonar/*
sudo mkdir -p ../volumes/sonar/{sonarqube-conf,sonarqube-data,sonarqube-logs,sonarqube-extensions}

printMessage "starting sonar container"
docker-compose up -d
counter=0

while ! curl --silent --fail -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=$SONAR_USER&previousPassword=admin&password=$SONAR_PASSWORD"; do
	sleep 1;
	counter=$((counter+1))
	echo "waiting for service up, counter $counter"
	if [ $counter -gt $MAX_WAIT_SEC ]
	then
		exitOnError "Error starting sonarqube server"
	fi
done

curl --silent -u "$SONAR_USER:$SONAR_PASSWORD" -X POST "http://localhost:9000/api/projects/create?name=default&project=default&visibility=public" || exitOnError "Error creating default project"

printMessage "stopping sonar container"
docker-compose down
