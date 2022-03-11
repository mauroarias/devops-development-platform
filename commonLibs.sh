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

parseJenkins () {
	printMessage "parsing docker file"
	docker_path=$(which docker)
	maven_path=$(mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout | sed 's!/repository!!')
	export docker_path=$docker_path
	export maven_path=$maven_path
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
