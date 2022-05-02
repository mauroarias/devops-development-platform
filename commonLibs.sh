#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
orange=`tput setaf 3`
blue=`tput setaf 4`
violet=`tput setaf 5`
agua=`tput setaf 6`
white=`tput setaf 7`
gris=`tput setaf 8`
reset=`tput sgr0`

#feature status
ACTIVATE=enabled
DEACTIVATE=disabled

#OS types
MAC_OS=mac
LINUX_OS=linux

#-------------------------------------------

reloadOsVar () {
	eval $(cat $profileFile | grep "export $1=") 
}

#printAlert <message to print> 
printAlert () {
	printTitleWithColor "$1" "${red}"
}

#printAlert <message to print> <color> 
printTitleWithColor () {
	echo "$2*******************************"
	echo "$1"
	echo "*******************************${reset}"
}

#printMessage <message to print> 
printMessage () {
	echo "${agua}$1${reset}"
}

#printMessageWithColor <message to print> <color> 
printMessageWithColor () {
	echo "$2$1${reset}"
}

#setSingleSecret <path secret> <secret name> <value> 
setSingleSecret () {
	vault kv put secret/$1/$2 $2=$3
}

#getSingleSecret <path secret> <secret name> 
getSingleSecret () {
	 vault kv get -field=$2 secret/$1/$2
}

#setJsonSecret <path secret> <secret json object> 
setJsonSecret () {
	vault kv put secret/$1 @$2
}

error () {
	exit 1
}

exitOnError () {
	printAlert "$1"
	error
}

kubectl () {
	minikube kubectl -- $1
}

traceOff () {
	set +e
}

traceOn () {
	set -e
}

parseJenkins () {
	printMessage "parsing docker file"
	docker_path=$(which docker)
	maven_path=$(mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout | sed 's!/repository!!')
	export docker_path=$docker_path
	export maven_path=$maven_path
}

downloadJenkinsCli () {
    counter=0
    while true 
    do 
        wget 'http://localhost:8080/jnlpJars/jenkins-cli.jar'
        wgetreturn=$?
        if [[ $wgetreturn -ne 0 ]]
        then
            sleep 1
            counter=$((counter+1))
            echo "waiting for service up, counter $counter"
            rm 
            if [ $counter -gt $MAX_WAIT_SEC_JENKINS ]
            then
                exitOnError "Error starting sonarqube server"
            fi
        else
            break
        fi
    done
}

waitSonarQubeUp () {
	counter=0
	while ! curl --silent --fail -H 'Content-Type: application/json' -u "$SONAR_USER:$SONAR_PASSWORD" -X GET "http://localhost:9000/api/user_tokens/search"; do
		sleep 1;
		counter=$((counter+1))
		echo "waiting for sonarqube up, counter $counter"
		if [ $counter -gt $MAX_WAIT_SEC_SONAR ]
		then
			exitOnError "Error starting sonarqube server"
		fi
	done
}

generateRandom () {
	size=$1
	cat /proc/sys/kernel/random/uuid | sed 's/[-]//g' | head -c $size
}

createUserPassCred () {
    printMessage "create $name credential"
    traceOff
    name=$1
    user=$2
    password=$3
	path=$4
    cat ${path}templating/credential_userpass_template.xml | sed "s|__NAME__|$name|g; s|__USER__|$user|g; s|__PASSWORD__|$password|g" > credential.xml
    createCred
    traceOn
}

createTextCred () {
    printMessage "create $name credential"
    traceOff
    name=$1
    secret=$2
	path=$3
    cat ${path}templating/credential_text_template.xml | sed "s|__NAME__|$name|g; s|__SECRET__|$secret|g" > credential.xml
    createCred
    traceOn
}

createCred () {
    java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket create-credentials-by-xml system::system::jenkins _ < credential.xml
    rm credential.xml
}

#-------------------------------------------

if [ -z "$profileFile" ];
then
	BASH_RC=$(eval ls ~/.bashrc)
	BASH_PROFILE=$(eval ls ~/.bash_profile)
	PROFILE=$(eval ls ~/.profile)

	if [ -f "$BASH_RC" ];
	then
		profileFile=$BASH_RC
	elif [ -f "$BASH_PROFILE" ];
	then
		profileFile=$BASH_PROFILE
	elif [ -f "$PROFILE" ];
	then
		profileFile=$PROFILE
	else
		exitOnError "profile not found"
	fi
	reloadOsVar "os"
	echo "$os"
fi

if [ -z "$os" ];
then
	echo "Please entry your OS '$MAC_OS' or '$LINUX_OS'"
	read
	os=${REPLY}
	if [ $os = $MAC_OS ];
    then
   		echo "profile MAC"
   	elif [ $os = $LINUX_OS ]
   	then
   		echo "profile linux"
   	else
   		exitOnError "this $os is not supported, '$MAC_OS' or '$LINUX_OS' are only supported"
   	fi
	sudo echo "export os=$os" >> $profileFile
	reloadOsVar "os"
fi
