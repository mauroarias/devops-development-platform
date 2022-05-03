#!/bin/bash

source ../commonLibs.sh

#****************************************

createJobJenkins () {
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

triggerJobJenkins () {
    JOB_NAME="$1"
    java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket build "$JOB_NAME" -s
}

#****************************************

LIB_VERSION=wip-0.2.0

printAlert "BE SURE THAT YOUR JENKINS IMAGE WAS STOPPED..."

printMessage "creating folder structure and clean up"
mkdir -p ../volumes/jenkins/config
sudo rm -rf ../volumes/jenkins/config/*
rm ./jenkins-cli.jar*

printMessage "building docker image"
docker build --no-cache -t jenkins:local . || exitOnError "error building image"

rm docker-compose.yml
parseJenkins
cat docker-compose.template | envsubst '${docker_path} ${maven_path} {GIT_HUB_ORGANIZATION} {GIT_EMAIL} {GIT_USER}'  > docker-compose.yml

printMessage "stating Jenkins & wait for to be available"
docker-compose up -d

downloadJenkinsCli

printMessage "applying config"
java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket apply-configuration < config/jenkins-config.yaml

createUserPassCred 'github-credentials' $GIT_HUB_USER $GIT_HUB_TOKEN './'
createUserPassCred 'bitbucket-credentials' $BITBUCKET_USER $BITBUCKET_PASSWD './'
createUserPassCred 'vault-credentials' $VAULT_USER $VAULT_PASSWORD './'
createUserPassCred 'sonar-credentials' $SONAR_USER $SONAR_PASSWORD './'
createTextCred 'vault-addr' $VAULT_ADDR './'

printMessage "creating jobs"
createJobJenkins 'create-service' 'templateCreateJob'
createJobJenkins 'create-ci-job' 'templateCreateCi'
createJobJenkins 'create-cd-job' 'templateCreateCd'
createJobJenkins 'create-ci-cd-jobs' 'templateCreateCiCd'

printMessage "initializing jobs"
triggerJobJenkins 'create-service' 
triggerJobJenkins 'create-ci-job'
triggerJobJenkins 'create-cd-job'
triggerJobJenkins 'create-ci-cd-jobs'

docker-compose down

echo "${green}Jenkins done... you are good!"