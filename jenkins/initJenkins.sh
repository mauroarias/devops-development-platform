#!/bin/bash

source ../commonLibs.sh

#****************************************

download_jenkins_cli () {
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
            if [ $counter -gt $MAX_WAIT_SEC ]
            then
                exitOnError "Error starting sonarqube server"
            fi
        else
            break
        fi
    done
}

create_job_jenkins () {
    CONFIG_FILE_NAME='./config.xml'
    CONFIG_TEMPLATE_FILE='templating/configFileCreateJobTemplate.xml'
    PIPELINE_TEMPLATE_FILE='./templating/JenkinsfileLibTemplate'
    JOB_NAME="$1"
    LIB_NAME="$2"
    echo "creating job $JOB_NAME"
    sed -n '/__PIPELINE__/q;p' "$CONFIG_TEMPLATE_FILE" > "$CONFIG_FILE_NAME"
    echo "<script>" >> "$CONFIG_FILE_NAME"
    cat "$PIPELINE_TEMPLATE_FILE" >> "$CONFIG_FILE_NAME"
    echo "</script>" >> "$CONFIG_FILE_NAME"
    grep -A 100 __PIPELINE__ "$CONFIG_TEMPLATE_FILE" | tail -n +2 >> "$CONFIG_FILE_NAME"
    sed -i "s/<description>/<description>$JOB_NAME/g; s/__LIB_VERSION__/$LIB_VERSION/g; s/__LIB_NAME__/$LIB_NAME/g" "$CONFIG_FILE_NAME"
    java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket create-job "$JOB_NAME" < "$CONFIG_FILE_NAME"
    rm "$CONFIG_FILE_NAME"
}

trigger_job_jenkins () {
    JOB_NAME="$1"
    java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket build "$JOB_NAME" -s
}

#****************************************

MAX_WAIT_SEC=60
LIB_VERSION=0.0.1

printAlert "BE SURE THAT YOUR JENKINS IMAGE WAS STOPPED..."

printMessage "creating folder structure and clean up"
mkdir -p ../volumes/jenkins/config
sudo rm -rf ../volumes/jenkins/config/*
rm ./jenkins-cli.jar*

printMessage "building docker image"
docker build --no-cache -t jenkins:local . || exitOnError "error building image"

rm docker-compose.yml
parseJenkins
cat docker-compose.template | envsubst '${docker_path} ${maven_path} ${GIT_HUB_TOKEN} ${GIT_HUB_USER} ${GIT_HUB_ORGANIZATION} ${GIT_EMAIL} ${GIT_USER} ${BITBUCKET_PASSWD} ${BITBUCKET_USER}'  > docker-compose.yml

printMessage "stating Jenkins & wait for to be available"
docker-compose up -d

download_jenkins_cli

printMessage "applying config"
java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket apply-configuration < ./jenkins-config.yaml

printMessage "creating jobs"
create_job_jenkins 'create-service' 'templateCreateJob'
create_job_jenkins 'create-ci-job' 'templateCreateCi'
create_job_jenkins 'create-cd-job' 'templateCreateCd'
create_job_jenkins 'create-ci-cd-jobs' 'templateCreateCiCd'

printMessage "initializing jobs"
trigger_job_jenkins 'create-service' 
trigger_job_jenkins 'create-ci-job'
trigger_job_jenkins 'create-cd-job'
trigger_job_jenkins 'create-ci-cd-jobs'

docker-compose down

echo "${green}Jenkins done... you are good!"