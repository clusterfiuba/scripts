#!/bin/bash

########## Auxiliar functions ##########
function echoError () {
	echo $'\e[1;31m'"${1}"$'\e[0m'
}

function echoSuccess () {
	echo $'\e[1;32m'"${1}"$'\e[0m'
}

function echoBold () {
	echo $'\e[1m'"${1}"$'\e[0m'
}

function exec_command() {
	echo "Ejecutando comando $1"
	eval $1
	if [ $? -ne 0 ]; then
		echoError "Error al ejecutar el comando $1"
		exit 1
	fi
	echoSuccess "OK"
}

echoBold "Instalando herramientas auxiliares"
echoBold "Instalando htop"
exec_command "yum install htop -y"
echoBold "Instalando vim"
exec_command "yum install vim -y"