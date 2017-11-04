#!/bin/bash

########## Auxiliar functions ##########
function display_help() { 
	echoBold "NAME"
	echo "	nfs_init"
	echo ""
	echoBold "SYNOPSIS"
	echo "	nfs_init -l [LOCAL_DIR] -r [REMOTE_DIR] -a [ADMNODE_IP]"
	echo ""
	echoBold "DESCRIPTION"
	echoBold "	-l [LOCAL_DIR]"
	echo "		name of local directory where mount the remote directory."
	echo ""
	echoBold "	-r [REMOTE_DIR]"
	echo "		name of remote directory to mount"
	echo ""
	echoBold "	-a [ADMNODE_IP]"
	echo "		ip of admnode."
	echo ""
	exit 1
}

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

# Main program

while getopts ":l:r:a:" o; do
    case "${o}" in
        l)
            LOCAL_DIR=${OPTARG}
            ;;
        r)
            REMOTE_DIR=${OPTARG}
	    ;;
        a)
            ADMNODE_IP=${OPTARG}
	    ;;
        *)
            display_help
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z $LOCAL_DIR ] || [ -z $REMOTE_DIR  ] || [ -z $ADMNODE_IP  ]; then
	display_help
fi

echoBold "Instalando nfs"
exec_command "yum install -y nfs-utils"
echoBold "Creando directorio local"
exec_command "mkdir -p $LOCAL_DIR"
echoBold "Montando directorio remoto"
exec_command "mount -t nfs $ADMNODE_IP:%REMOTE_DIR $LOCAL_DIR"
