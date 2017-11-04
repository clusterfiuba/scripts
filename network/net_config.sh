#!/bin/bash

# Auxiliar functions

function display_help() { 
	echoBold "NAME"
	echo "	net_config"
	echo ""
	echoBold "SYNOPSIS"
	echo "	net_config -t [TYPE] -a [NETWORK_ADAPTER_NAME] -i [IP_ADDRESS] -n [NODE_NAME] -g [GATEWAY]"
	echo ""
	echoBold "DESCRIPTION"
	echoBold "	-t [TYPE]"
	echo "		type of node in the cluster: admnode or cnode."
	echo ""
	echoBold "	-a [NETWORK_ADAPTER_NAME]"
	echo "		name of the netcard device which result of ip addr command. Example enp63s0"
	echo ""
	echoBold "	-i [IP_ADDRESS]"
	echo "		ip of the node in the internal network of cluster."
	echo ""
	echoBold "	-n [NODE_NAME]"
	echo "		name of the node in the cluster. Example admnode, cnode1, etc."
	echo ""
	echoBold "	-g [GATEWAY]"
	echo "		in the case of cnode set the ip of admnode otherwise set -"
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

# Parameters
IFCFG_PATH=/etc/sysconfig/network-scripts/ifcfg-
HOSTNAME_FILE=/etc/hostname
RESOLV_CONF_FILE=/etc/resolv.conf
NETWORK_CONFIG_FILE=/etc/sysconfig/network

# Main program

while getopts ":t:a:i:n:g:" o; do
    case "${o}" in
        t)
            TYPE=${OPTARG}
            ;;
        a)
            NETWORK_ADAPTER_NAME=${OPTARG}
	    ;;
        i)
            IP_ADDRESS=${OPTARG}
	    ;;
        n)
            NODE_NAME=${OPTARG}
	    ;;
	g)
	    GATEWAY=${OPTARG}
	    ;;
        *)
            display_help
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z $TYPE ] || [ -z $NETWORK_ADAPTER_NAME  ] || [ -z $IP_ADDRESS  ] || [ -z $NODE_NAME  ] || [ -z $GATEWAY  ]; then
	display_help
fi

echoBold "Actualizando $IFCFG_PATH$NETWORK_ADAPTER_NAME"
exec_command "ls $IFCFG_PATH$NETWORK_ADAPTER_NAME > /dev/null"
exec_command "echo IPADDR=$IP_ADDRESS >> $IFCFG_PATH$NETWORK_ADAPTER_NAME"
exec_command "sed -i 's-\(BOOTPROTO=\)\(.*\)-\1static-g' $IFCFG_PATH$NETWORK_ADAPTER_NAME"
echo ""
echoBold "Actualizando el archivo $HOSTNAME_FILE"
exec_command "echo $NODE_NAME > $HOSTNAME_FILE"
echo ""
echoBold "Actualizando el archivo $RESOLV_CONF_FILE"
exec_command "echo nameserver 8.8.8.8 > $RESOLV_CONF_FILE"
exec_command "echo nameserver 8.8.8.4 >> $RESOLV_CONF_FILE"
echo ""
echoBold "Actualizando el archivo $NETWORK_CONFIG_FILE"
exec_command "echo NETWORKING=yes > $NETWORK_CONFIG_FILE"
if [ $TYPE == "cnode" ]; then
	exec_command "echo GATEWAY=$GATEWAY >> $NETWORK_CONFIG_FILE"
fi
echo ""
echoBold "Bajando el firewall"
exec_command "systemctl stop firewalld.service"
echoBold "Deshabilitando el firewall"
exec_command "systemctl disable firewalld.service"
echoBold "Reiniciando servicio de red"
exec_command "systemctl restart network"
exit 0
