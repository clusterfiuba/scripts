#!/bin/bash

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
        if [ $STEP -lt $INITSTEP ]; then	
	        STEP=$((STEP+1))
                return
        fi
        echo "Ejecutando comando $1"
        eval $1
        if [ $? -ne 0 ]; then
                echoError "Error al ejecutar el comando $1 paso $STEP"
                echo $STEP > $STEPFILE
                exit 1
        fi
        STEP=$((STEP+1))
        echoSuccess "OK"
}
