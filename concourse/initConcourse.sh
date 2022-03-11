#!/bin/bash

source ../commonLibs.sh

MAX_WAIT_SEC=10
TARGET=default

getArch () {
	if [ $os = $MAC_OS ];
	then
		arch="amd64&platform=darwin"
	elif [ $os = $LINUX_OS ]
	then
		arch="amd64&platform=linux"
	fi
}

waitConcourseUp () {
	counter=0
	while ! curl --silent --fail "http://localhost:8080/api/v1/info"
	do
		sleep 1;
		counter=$((counter+1))
		rm -f fly
		echo "waiting for service up, counter $counter"
		if [ $counter -gt $MAX_WAIT_SEC ]
		then
			exitOnError "Error starting concourse"
		fi
	done
}


downloadCli () {
	getArch
	printMessage "getting fly from arch $arch"
	counter=0
	curl --silent "http://localhost:8080/api/v1/cli?arch=$arch" -o fly
	sudo chmod +x ./fly && sudo mv ./fly /usr/local/bin/	
}

#****************************************

printAlert "BE SURE THAT YOUR CONCOURSE IMAGE WAS STOPPED..."

printMessage "stating Concourse & wait for to be available"
docker-compose up -d
sleep 5
	
waitConcourseUp
fly -v || downloadCli
fly -t $TARGET login -c http://localhost:8080 -u admin -p admin1
fly -t $TARGET sync

#docker-compose down

echo "${green}Concourse done... you are good!"