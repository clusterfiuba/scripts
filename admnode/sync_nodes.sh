#!/bin/bash

# Import common functions
. ../common/common_functions.sh

# Global vars
export STEP=0
export INITSTEP=0
export STEPFILE=step.txt
export IFCFG_PATH=/etc/sysconfig/network-scripts/ifcfg-
export HOSTNAME_FILE=/etc/hostname
export HOSTS_FILE=/etc/hosts
export RESOLV_CONF_FILE=/etc/resolv.conf
export NETWORK_CONFIG_FILE=/etc/sysconfig/network
export YUM_CONF_FILE=/etc/yum.conf

# Auxiliar functions
function display_help() { 
	echoBold "NAME"
	echo "	sync_nodes"
	echo ""
	echoBold "SYNOPSIS"
	echo "	sync_nodes -l [LAST_NODE_INSTALL_NAME] -i [LAST_NODE_INSTALL_IP]"
	echo ""
	echoBold "DESCRIPTION"
	echoBold "	LAST_NODE_INSTALL_NAME"
	echo "		Name of the last node installed"
	echo ""
        echoBold "      LAST_NODE_INSTALL_IP"
        echo "          IP of the last node installed"
        echo ""
	echoBold "EXAMPLE"
	echo "	./sync_nodes.sh -l cnode3 -i 192.168.1.23"
	echo ""
	exit 1
}

# Main program

while getopts ":l:i:" o; do
    case "${o}" in
        l)
           LAST_NODE_INSTALL_NAME=${OPTARG}
           ;;
        i)
           LAST_NODE_INSTALL_IP=${OPTARG}
           ;;

        *)
           display_help
           ;;
    esac
done
shift $((OPTIND-1))
if [ -z $LAST_NODE_INSTALL_NAME ] || [ -z $LAST_NODE_INSTALL_IP ]; then
	display_help
fi

# INTERCAMBIO DE CLAVES
echoBold "Realizando el intercambio de claves RSA para el ultimo nodo instalado"
exec_command "ssh-copy-id root@$LAST_NODE_INSTALL_NAME"
echoSuccess "Intercambio de claves realizado exitosamente"
echo ""

echoBold "Sincronizando los archivos de configuracion con el resto de los nodos"
IFS=$'\n'
for reg in $(grep ^NodeName /etc/slurm/slurm.conf | grep -v $LAST_NODE_INSTALL_NAME); do
	node=$(echo $reg | cut -f2 -d= | cut -f1 -d\ )
	echoBold "Sincronizando el nodo $node"
	scp /etc/slurm/slurm.conf $node:/etc/slurm
	scp /etc/ganglia/gmondm.conf $node:/etc/ganglia
	ssh $node "echo $LAST_NODE_INSTALL_IP $LAST_NODE_INSTALL_NAME >> /etc/hosts"
	ssh $node "systemctl restart slurmd"
	ssh $node "systemctl restart gmond"
	echoSuccess "Nodo $node sincronizado exitosamente"
done
echoBold "Reiniciando servicios locales"
systemctl restart slurmctld
systemctl restart gmetad
systemctl restart gmond
systemctl restart httpd
echoSuccess "Sincronizacion exitosa"
exit 0
