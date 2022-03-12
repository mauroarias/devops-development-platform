#!/bin/bash

CONCOURSE_CI=Concourse
JENKINS_CI=jenkins

SONAR_USER=admin
SONAR_PASSWORD=passwd

#ACTIVATE or DEACTIVATE
minikubeOn=$DEACTIVATE
istioOn=$DEACTIVATE
#CONCOURSE_CI or JENKINS_CI ..... concourse is not supported yt
ci=$JENKINS_CI
