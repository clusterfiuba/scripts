#!/bin/bash

# Auxiliar functions

function display_help() { 
	echoBold "NAME"
	echo "	node_install"
	echo ""
	echoBold "SYNOPSIS"
	echo "	node_install -t [TYPE] -n [NTP_SYNC_NODE]"
	echo ""
	echoBold "DESCRIPTION"
	echoBold "	-t [TYPE]"
	echo "		type of node in the cluster: admnode or cnode."
	echo ""
	echoBold "	-n [NTP_SYNC_NODE]"
	echo "		IP or name of the admnode with which to synchronize the date and time."
	echo "		If this is the admnode, enter -"
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

while getopts ":t:n:" o; do
    case "${o}" in
        t)
            TYPE=${OPTARG}
            ;;
        n)
            NTP_SYNC_NODE=${OPTARG}
            ;;
        *)
            display_help
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z $TYPE ]; then
	display_help
fi
if [ "$TYPE" != "admnode" ] && [ "$TYPE" != "cnode" ]; then
	display_help	
fi
if [ "$TYPE" == "cnode" ] && [ -z $NTP_SYNC_NODE ]; then
	display_help	
fi

# Main
echoBold "Instalando Munge"
echo ""
echo "Creando usuarios ..."
export MUNGEUSER=981
export SLURMUSER=982
exec_command "groupadd -g $MUNGEUSER munge"
exec_command "useradd -m -c \"MUNGE Uid 'N' Gid Emporium\" -d /var/lib/munge -u $MUNGEUSER -g munge -s /sbin/nologin munge"
exec_command "groupadd -g $SLURMUSER slurm"
exec_command "useradd -m -c \"SLURM workload manager\" -d /var/lib/slurm -u $SLURMUSER -g slurm -s /bin/bash slurm"
echo ""
echo "Instalando paquetes ..."
exec_command "yum install epel-release munge munge-libs munge-devel -y"
exec_command "cp munge.key /etc/munge"
exec_command "chown -R munge: /etc/munge/ /var/log/munge/"
exec_command "chmod 0777 /etc/munge /var/log/munge"
echo ""
echo "Iniciando Munge ..."
exec_command "systemctl enable munge"
exec_command "systemctl start munge"
exec_command "systemctl status munge"
echoSuccess "Munge instalado exitosamente"
echo ""
echoBold "Instalando Surm"
echo ""
echo "Instalando paquetes ..."
exec_command "yum install openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad perl-ExtUtils-MakeMaker gcc -y"
exec_command "yum --nogpgcheck localinstall slurm-17.02.7-1.el7.centos.x86_64.rpm slurm-contribs-17.02.7-1.el7.centos.x86_64.rpm slurm-devel-17.02.7-1.el7.centos.x86_64.rpm slurm-munge-17.02.7-1.el7.centos.x86_64.rpm slurm-openlava-17.02.7-1.el7.centos.x86_64.rpm slurm-pam_slurm-17.02.7-1.el7.centos.x86_64.rpm slurm-perlapi-17.02.7-1.el7.centos.x86_64.rpm slurm-plugins-17.02.7-1.el7.centos.x86_64.rpm slurm-slurmdbd-17.02.7-1.el7.centos.x86_64.rpm slurm-sql-17.02.7-1.el7.centos.x86_64.rpm slurm-torque-17.02.7-1.el7.centos.x86_64.rpm -y"
echo ""
echo "Configurando Slurm ..."
exec_command "cp slurm.conf /etc/slurm/"
exec_command "cgroup.conf /etc/slurm/"
exec_command "mkdir /var/spool/slurmd"
exec_command "chown slurm: /var/spool/slurmd"
exec_command "chmod 755 /var/spool/slurmd"
exec_command "touch /var/log/slurmd.log"
exec_command "chown slurm: /var/log/slurmd.log"
echo ""
echo "Chequeando que la configuracion de Slurm sea correcta ..."
exec_command "slurmd -C"
echo ""
echoBold "Sincronizando la fecha y hora del nodo del cnode con el admnode"
exec_command "yum install ntp -y"
exec_command "unlink /etc/localtime"
exec_command "ln -s /usr/share/zoneinfo/America/Buenos_Aires /etc/localtime"
exec_command "chkconfig ntpd on"
if [ "$TYPE" == "cnode" ]; then
	exec_command "ntpdate $NTP_SYNC_NODE"
fi
exec_command "systemctl start ntpd"
echo ""
echoBold "Iniciando slurm"
exec_command "systemctl enable slurmd.service"
exec_command "systemctl start slurmd.service"
exec_command "systemctl status slurmd.service"
echo ""
echoSuccess "Slurm instalado exitosamente"

