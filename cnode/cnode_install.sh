#!/bin/bash

# Import common functions
. ../common/common_functions.sh

# Import params
#. cnode_install.param

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
	echo "	cnode_install"
	echo ""
	echoBold "SYNOPSIS"
	echo "	cnode_install -t [NETWORK_ADAPTER_NAME] -a [IP_ADDRESS] -n [NODE_NAME] -d [ADMNODE_IP] -e [ADMNODE_NAME] -c [CLUSTER_PROXY]"
	echo ""
	echoBold "DESCRIPTION"
	echoBold "	NETWORK_ADAPTER_NAME"
	echo "		Name of the netcard device which result of ip addr command. Example enp63s0"
	echo ""
	echoBold "	IP_ADDRESS"
	echo "		IP of the node in the internal network of cluster"
	echo ""
	echoBold "	NODE_NAME"
	echo "		Name of the node in the cluster. Example cnode1, etc."
	echo ""
	echoBold "	ADMNODE_IP"
	echo "		IP of the admnode in the internal network of cluster"
	echo ""
	echoBold "	ADMNODE_NAME"
	echo "		Name of the node in the cluster. Example admnode, etc."
	echo ""
	echoBold "	CLUSTER_PROXY"
	echo "		Name of the node in the cluster. Example admnode, etc."
	echo ""
	echoBold "EXAMPLE"
	echo "	./cnode_install.sh -t ens33 -a 192.168.1.21 -n cnode1 -d 192.168.252.134 -e admnode -c http://admnode:3128"
	echo ""
	exit 1
}

# Main program

while getopts ":t:a:n:d:e:c:" o; do
    case "${o}" in
        t)
           NETWORK_ADAPTER_NAME=${OPTARG}
           ;;
        a)
           IP_ADDRESS=${OPTARG}
           ;;
        n)
           NODE_NAME=${OPTARG}
           ;;
        d)
           ADMNODE_IP=${OPTARG}
           ;;
        e)
           ADMNODE_NAME=${OPTARG}
           ;;
        c)
           CLUSTER_PROXY=${OPTARG}
           ;;
        *)
           display_help
           ;;
    esac
done
shift $((OPTIND-1))

echo $NETWORK_ADAPTER_NAME
echo $IP_ADDRESS
echo $NODE_NAME
echo $ADMNODE_IP
echo $ADMNODE_NAME
echo $CLUSTER_PROXY


if [ -z $NETWORK_ADAPTER_NAME ] || [ -z $NODE_NAME ] || [ -z $IP_ADDRESS ] || [ -z $ADMNODE_IP ] || [ -z $ADMNODE_NAME ] || [ -z $CLUSTER_PROXY ] ; then
	display_help
fi

# Main
[ -f $STEPFILE ] && INITSTEP=$(cat $STEPFILE)

# RED
echoBold "Configurando la red"
exec_command "ls $IFCFG_PATH$NETWORK_ADAPTER_NAME > /dev/null"
exec_command "echo IPADDR=$IP_ADDRESS >> $IFCFG_PATH$NETWORK_ADAPTER_NAME"
exec_command "sed -i 's-\(BOOTPROTO=\)\(.*\)-\1static-g' $IFCFG_PATH$NETWORK_ADAPTER_NAME"
exec_command "echo nameserver 8.8.8.8 > $RESOLV_CONF_FILE"
exec_command "echo nameserver 8.8.8.4 >> $RESOLV_CONF_FILE"
exec_command "echo NETWORKING=yes > $NETWORK_CONFIG_FILE"
exec_command "echo GATEWAY=$ADMNODE_IP >> $NETWORK_CONFIG_FILE"
exec_command "echo $ADMNODE_IP $ADMNODE_NAME >> $HOSTS_FILE"
exec_command "systemctl stop firewalld.service"
exec_command "systemctl disable firewalld.service"
exec_command "systemctl restart network"
echoSuccess "Red configurada exitosamente"
echo ""

# INTERCAMBIO DE CLAVES
echoBold "Realizando el intercambio de claves RSA"
exec_command "ssh-keygen"
exec_command "ssh-copy-id root@$ADMNODE_NAME"
echoSuccess "Intercambio de claves realizado exitosamente"
echo ""

# PROGRAMAS AUXILIARES
echoBold "Instalando programas auxiliares"
exec_command "sed -i \"s-\(proxy=\)\(.*\)-\1$CLUSTER_PROXY-g\" $YUM_CONF_FILE"
exec_command "yum update -y"
exec_command "yum groupinstall \"Development Tools\" -y"
exec_command "yum groupinstall \"Compatibility Libraries\" -y"
exec_command "yum install epel-release -y"
exec_command "yum install htop -y"
exec_command "yum install vim -y"
exec_command "yum install octave -y"
exec_command "yum install m4 gcc glib2-devel which libXv openssh-clients -y"
exec_command "yum install python-pip -y"
exec_command "yum install python-devel -y"
exec_command "pip install --proxy=$CLUSTER_PROXY --upgrade pip"
exec_command "pip install --proxy=$CLUSTER_PROXY oct2py"
exec_command "pip install --proxy=$CLUSTER_PROXY numpy"
exec_command "pip install --proxy=$CLUSTER_PROXY scipy"
exec_command "pip install --upgrade pip"
exec_command "pip install oct2py"
exec_command "pip install  numpy"
exec_command "pip install scipy"
echoSuccess "Programas auxiliares instalados exitosamente"
echo ""

# SELINUX
echoBold "Deshabilitando SELINUX"
exec_command "sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/sysconfig/selinux"
echoSuccess "SELINUX deshabilitado exitosamente"
echo ""

# NTP
echoBold "Instalando NTP"
exec_command "yum install ntp -y"
exec_command "unlink /etc/localtime"
exec_command "ln -s /usr/share/zoneinfo/America/Buenos_Aires /etc/localtime"
exec_command "chkconfig ntpd on"
exec_command "sed -i '/^server .*/d' /etc/ntp.conf"
exec_command "echo \"server $ADMNODE_IP prefer\" >> /etc/ntp.conf"
exec_command "systemctl enable ntpd"
exec_command "systemctl start ntpd"
exec_command "ntpdate admnode"
echoSuccess "NTP instalado exitosamente"
echo ""

# LDAP
exec_command "yum install -y openldap-clients nss-pam-ldapd"
exec_command "authconfig --enableldap --enableldapauth --ldapserver=$ADMNODE_NAME --ldapbasedn=\"dc=quipu,dc=local\" --enablemkhomedir --update"
exec_command "systemctl restart nslcd"
echo ""

# NFS
echoBold "Instalando NFS y configurando SCRATCH"
exec_command "yum install nfs-utils -y"
exec_command "mkdir -p /scratch"
exec_command "mount $ADMNODE_NAME:/scratch /scratch"
echoSuccess "NFS instalado exitosamente"
echo ""

# SSH
echoBold "Configurando ssh"
exec_command "echo \"Match Host admnode\" >> /etc/ssh/sshd_config"
exec_command "echo \"    AllowUsers root\" >> /etc/ssh/sshd_config"
exec_command "systemctl restart sshd"
echoSuccess "SSH configurado exitosamente"
echo ""

# MUNGE
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
echo "Instalando dependencias ..."
exec_command "yum install epel-release munge munge-libs munge-devel -y"
exec_command "cp ../slurm/munge.key /etc/munge"
exec_command "chown -R munge: /etc/munge/"
exec_command "chown -R munge: /var/log/munge/"
exec_command "chmod 0700 -R /etc/munge"
exec_command "chmod 0700 -R /var/log/munge"
echo ""
echo "Iniciando Munge ..."
exec_command "systemctl enable munge"
exec_command "systemctl start munge"
exec_command "systemctl status munge"
echoSuccess "Munge instalado exitosamente"
echo ""

# SLURM
echoBold "Instalando Slurm"
echo ""
echo "Instalando paquetes ..."
exec_command "yum install openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad perl-ExtUtils-MakeMaker gcc -y"
#exec_command "yum --nogpgcheck localinstall slurm-17.02.7-1.el7.centos.x86_64.rpm slurm-contribs-17.02.7-1.el7.centos.x86_64.rpm slurm-devel-17.02.7-1.el7.centos.x86_64.rpm slurm-munge-17.02.7-1.el7.centos.x86_64.rpm slurm-openlava-17.02.7-1.el7.centos.x86_64.rpm slurm-pam_slurm-17.02.7-1.el7.centos.x86_64.rpm slurm-perlapi-17.02.7-1.el7.centos.x86_64.rpm slurm-plugins-17.02.7-1.el7.centos.x86_64.rpm slurm-slurmdbd-17.02.7-1.el7.centos.x86_64.rpm slurm-sql-17.02.7-1.el7.centos.x86_64.rpm slurm-torque-17.02.7-1.el7.centos.x86_64.rpm -y"
exec_command "yum --nogpgcheck localinstall ../slurm/*.rpm -y"
echo ""
echo "Configurando Slurm ..."
exec_command "scp $ADMNODE_NAME:/etc/slurm/slurm.conf /etc/slurm"
exec_command "cp ../slurm/cgroup.conf /etc/slurm/"
exec_command "mkdir -p /var/spool/slurmd"
exec_command "chown slurm: /var/spool/slurmd"
exec_command "chmod 755 /var/spool/slurmd"
exec_command "touch /var/log/slurmd.log"
exec_command "chown slurm: /var/log/slurmd.log"
grep "^NodeName=$NODE_NAME " /etc/slurm/slurm.conf 1 > /dev/null 2 >&1
if [ $? -ne 0 ]; then
        # No existe el nodo
        exec_command "echo \"NodeName=$NODE_NAME NodeAddr=$IP_ADDRESS CPUs=1 State=UNKNOWN\" >> /etc/slurm/slurm.conf"
        NODE_NUMBER=$(echo $NODE_NAME | sed 's/cnode//g')
        sed -i "s/\(^PartitionName.*1-\)\(.*\)\(\].*$\)/\1$NODE_NUMBER\3/g" /etc/slurm/slurm.conf
fi
echo ""
echo "Chequeando que la configuracion de Slurm sea correcta ..."
exec_command "slurmd -C"
echoBold "Iniciando slurm"
exec_command "systemctl enable slurmd.service"
exec_command "systemctl start slurmd.service"
exec_command "systemctl status slurmd.service"
echoBold "Actualizando la configuracion del admnode"
exec_command "scp /etc/slurm/slurm.conf $ADMNODE_NAME:/etc/slurm"
exec_command "ssh -t $ADMNODE_NAME \"systemctl restart slurmctld\""
echoSuccess "Slurm instalado exitosamente"

# GANGLIA
echoBold "Instalando Ganglia"
exec_command "yum install libconfuse -y"
exec_command "yum install libconfuse-devel -y"
exec_command "yum install -y ../ganglia/*.rpm"
exec_command "scp $ADMNODE_NAME:/etc/ganglia/gmond.conf /etc/ganglia"
exec_command "echo \"\" >> /etc/ganglia/gmond.conf"
exec_command "echo \"udp_send_channel {\" >> /etc/ganglia/gmond.conf"
exec_command "echo \"  host = $NODE_NAME\" >> /etc/ganglia/gmond.conf"
exec_command "echo \"  port = 8649\" >> /etc/ganglia/gmond.conf"
exec_command "echo \"  ttl = 1\" >> /etc/ganglia/gmond.conf"
exec_command "echo \"  }\" >> /etc/ganglia/gmond.conf"
exec_command "scp /etc/ganglia/gmond.conf $ADMNODE_NAME:/etc/ganglia"
exec_command "ssh -t $ADMNODE_NAME \"systemctl restart gmond\""
exec_command "chkconfig gmond on"
exec_command "systemctl start gmond"
echoSuccess "Ganglia instalado exitosamente"
echo ""
echoSuccess "cnode instalado exitosamente!!!"
