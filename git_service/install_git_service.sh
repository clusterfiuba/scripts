#!/bin/bash

# Global variables
SERVICE_DESCRIPTOR_FILE="/etc/systemd/system/git_service.service"
SERVICE_CONF_FILE="/etc/conf.d/git_service"
SERVICE_SCRIPT_NAME="git_service.sh"

# Auxiliar functions

function echoDim () {
    if [ -z "$2" ]; then
        echo $'\e[2m'"${1}"$'\e[0m'
    else
        echo -n $'\e[2m'"${1}"$'\e[0m'
    fi
}

function echoError () {
    echo $'\e[1;31m'"${1}"$'\e[0m'
}

function echoSuccess () {
    echo $'\e[1;32m'"${1}"$'\e[0m'
}

function echoDot () {
    echoDim "." "append"
}

function echoBold () {
    echo $'\e[1m'"${1}"$'\e[0m'
}

function askBold () {
    echo -n $'\e[1m'"${1}"$'\e[0m'
}

function listFiles () {
    find "${1}" -maxdepth 1 -mindepth 1 \( ! -iname ".*" \)| rev | cut -d '/' -f1 | rev | awk NF
}

function listDirectories () {
    IFS=' ' read -r -a dirs <<< `ls -l --time-style="long-iso" $1 | egrep '^d' | awk '{print $8}'`
    for dir in "${dirs[@]}"
    do
        echo "${dir}"
    done
}

function display_help() { 
	echoBold "NAME"
	echo "	install_git_service"
	echo ""
	echoBold "SYNOPSIS"
	echo "	install_git_service.sh -d [INSTALATION DIRECTORY]"
	echo ""
	echoBold "DESCRIPTION"
	echoBold "	-d [INSTALATION DIRECTORY]"
	echo "		directory where install service script"
	echo ""
	display_cheat_sheet
	exit 1
}

function display_cheat_sheet() {
	echoBold "CHEAT SHEET"
	echoBold "	Iniciar el servicio"
	echo "		systemctl start git_service.service"
	echoBold "	Detener el servicio"
	echo "		systemctl stop git_service.service"
	echoBold "	Consultar el estado del servicio"
	echo "		systemctl status git_service.service"
	echoBold "	Iniciar el servicio en el arranque del equipo"
	echo "		systemctl enable git_service.service"
	echoBold "	Detener el servicio en el arranque del equipo"
	echo "		systemctl disable git_service.service"
	echoBold "	Consultar los logs del dia del servicio"
	echo "		journalctl -u nginx.service -u php-fpm.service --since today"
}

function exec_command() {
	if [ -z $2 ]; then
		echo "Ejecutando $1"
	fi
	eval $1
	if [ $? -ne 0 ]; then
		echoError "Error al ejecutar el comando $1"
		exit 1
	fi
}

function reg_service() {
	exec_command "echo [Unit] > $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo Description=Git Service >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo After=syslog.target >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo [Service] >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo EnvironmentFile=$SERVICE_CONF_FILE >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo ExecStart=$d/$SERVICE_SCRIPT_NAME '\$'GITHUB_URI '\$'GITHUB_USER '\$'GITHUB_PASSWORD '\$'PULL_TIME '\$'WORKING_DIRECTORY >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo Restart=on-abort >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo [Install] >> $SERVICE_DESCRIPTOR_FILE" "--silent"
	exec_command "echo WantedBy=multi-user.target >> $SERVICE_DESCRIPTOR_FILE" "--silent"
}

function install_conf() {
	exec_command "echo \# Intervalo de tiempo en el que se chequea la ip > $SERVICE_CONF_FILE" "--silent"
	exec_command "echo PULL_TIME= >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo \# URI del repositorio Git-Hub >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo GITHUB_URI= >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo \# Usuario de la cuenta Git-Hub >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo GITHUB_USER= >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo \# Password de la cuenta Git-Hub >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo GITHUB_PASSWORD= >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo \# Working directory de Git >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo WORKING_DIRECTORY= >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo \# Home del usuario. Ejemplo: /root >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo USER_HOME= >> $SERVICE_CONF_FILE" "--silent"
	exec_command "echo >> $SERVICE_CONF_FILE" "--silent"

}

while getopts ":d:" o; do
    case "${o}" in
        d)
            export d=${OPTARG}
            ;;
        *)
            display_help
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z $d ]; then
	display_help
fi

echo "Instalando GIT ..." "."
exec_command "yum install git -y"
echoSuccess "OK"
echo "Instalando script del servicio ..."
exec_command "cp $SERVICE_SCRIPT_NAME $d"
exec_command "chmod 700 $d/$SERVICE_SCRIPT_NAME"
exec_command "chown root.root $d/$SERVICE_SCRIPT_NAME"
echoSuccess "OK"
echo "Registrando el servicio ..."
reg_service
echoSuccess "OK"
echo "Instalando configuracion del servicio ..."
exec_command "mkdir -p /etc/conf.d"
install_conf
echoSuccess "OK"
echoBold "ATENCION"
echo "Antes de iniciar el servicio configurar los parametros del mismo en el archivo /etc/conf.d/git_service"
echo ""
display_cheat_sheet
echoSuccess "Git Service instalado exitosamente"
