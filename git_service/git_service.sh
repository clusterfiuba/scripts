#!/bin/bash

GITHUB_URI=$1
GITHUB_USER=$2
GITHUB_PASSWORD=$3
PULL_TIME=$4
WORKING_DIRECTORY=$5
USER_HOME=$6

REPONAME=$(echo $GITHUB_URI | cut -f5 -d/ | cut -f1 -d.)

function exec_command() {
    eval $1
    if [ $? -ne 0 ]; then
        echo "Error al ejecutar el comando $1"
        #exit 1
    fi
}

if [ ! -d $WORKING_DIRECTORY ]; then
    exec_command "mkdir $WORKING_DIRECTORY"
fi
exec_command "cd $WORKING_DIRECTORY"

if [ ! -d $REPONAME ]; then
    exec_command "git clone $GITHUB_URI"
fi
export HOME="$USER_HOME"
git config --global user.email "cluster.fiuba@gmail.com"
git config --global user.name "clusterfiuba"
GITHUB_URI=$(echo $GITHUB_URI | sed 's/github/$GITHUB_USER:$GITHUB_PASSWORD@github/g')
while true; do
   echo "Iniciando una nueva verificacion de IP"
   exec_command "cd $WORKING_DIRECTORY/quipu"
   exec_command "git fetch --all"
   exec_command "git reset --hard origin/master"
   GIT_IP=$(cat $WORKING_DIRECTORY/quipu/README.md)
   CLUSTER_IP=$(ifconfig | grep inet | sed "3q;d" | sed -e 's/^[[:space:]]*//' | cut -f2 -d" ")
   echo "IP del cluster: $CLUSTER_IP"
   echo "IP de GITHUB: $GIT_IP"
   if [ "$CLUSTER_IP" != "$GIT_IP" ]; then
	echo "cambio la IP. Actualizando el repositorio."
        exec_command "echo $CLUSTER_IP > README.md"
        exec_command "git add *"
        exec_command "git commit -m \"Change IP\""
        exec_command "git push $GITHUB_URI --all"
        echo "IP actualizada"
    else
        echo "La IP no ha cambiado"
    fi
    sleep $PULL_TIME
done
