#!/bin/bash

# Import common functions
. ../common/common_functions.sh

#Global vars

export STEP=0
export INITSTEP=0
export STEPFILE=step.txt


# Main program

[ -f $STEPFILE ] && INITSTEP=$(cat $STEPFILE)


# Main
#exec_command "echo probando un paso antes del error"
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
exec_command "cp ../slurm/munge.key /etc/munge/munge.key"
exec_command "chown munge: /etc/munge/munge.key"
exec_command "chmod 0400 /etc/munge/munge.key"
echo ""
echo "Iniciando Munge ..."
exec_command "systemctl enable munge"
exec_command "systemctl start munge"
exec_command "systemctl status munge"
echoSuccess "Munge instalado exitosamente"
echo ""
echoBold "Sincronizando la fecha y hora del nodo del cnode con el admnode"
exec_command "yum install ntp -y"
exec_command "unlink /etc/localtime"
exec_command "ln -s /usr/share/zoneinfo/America/Buenos_Aires /etc/localtime"
exec_command "cp ../ntp/ntp.conf.server /etc/ntp.conf"
exec_command "systemctl enable ntpd"
exec_command "systemctl start ntpd"
echo ""
echoBold "Instalando Slurm"
echo ""
echo "Instalando paquetes ..."
exec_command "yum install openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad perl-ExtUtils-MakeMaker gcc -y"
#exec_command "cd ../slurm"
exec_command "yum --nogpgcheck localinstall ../slurm/*.rpm -y"
#exec_command "yum --nogpgcheck localinstall slurm-17.02.7-1.el7.centos.x86_64.rpm slurm-contribs-17.02.7-1.el7.centos.x86_64.rpm slurm-devel-17.02.7-1.el7.centos.x86_64.rpm slurm-munge-17.02.7-1.el7.centos.x86_64.rpm slurm-openlava-17.02.7-1.el7.centos.x86_64.rpm slurm-pam_slurm-17.02.7-1.el7.centos.x86_64.rpm slurm-perlapi-17.02.7-1.el7.centos.x86_64.rpm slurm-plugins-17.02.7-1.el7.centos.x86_64.rpm slurm-slurmdbd-17.02.7-1.el7.centos.x86_64.rpm slurm-sql-17.02.7-1.el7.centos.x86_64.rpm slurm-torque-17.02.7-1.el7.centos.x86_64.rpm -y"
#exec_command "cd ../admnode"
echo ""
echo "Configurando Slurm ..."
exec_command "cp ../slurm/slurm.conf /etc/slurm/"
exec_command "cp ../slurm/cgroup.conf /etc/slurm/"

exec_command "mkdir /var/spool/slurmctld"
exec_command "chown slurm: /var/spool/slurmctld"
exec_command "chmod 755 /var/spool/slurmctld"
exec_command "touch /var/log/slurmctld.log"
exec_command "chown slurm: /var/log/slurmctld.log"
exec_command "touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log"
exec_command "chown slurm: /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log"
exec_command "slurmd -C"
exec_command "systemctl stop firewalld"
exec_command "systemctl disable firewalld"


exec_command "systemctl enable slurmctld.service"
exec_command "systemctl start slurmctld.service"
exec_command "systemctl status slurmctld.service"
echo ""
echo "Instalando squid"
exec_command "yum -y install squid"
echo ""
echo "configurando proxy"
#exec_command "cp squid/squid.conf /etc/squid/squid.conf"
#exec_command "echo "
exec_command "systemctl enable squid"
exec_command "systemctl start squid"
exec_command "echo \"http_proxy=\"http://proxy.fi.uba.ar:8080/\"\""
exec_command "echo \"https_proxy=\"https://proxy.fi.uba.ar:8080/\"\""
exec_command "echo \"ftp_proxy=\"ftp://proxy.fi.uba.ar:8080/\"\""
exec_command "echo \"no_proxy=\".quipu,.local,admnode,cnode\"\""
echo ""
echo "Instalando ldap server"
exec_command "yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel"
exec_command "systemctl start slapd.service"
exec_command "systemctl enable slapd.service"
#exec_command "netstat -antup | grep -i 389"
exec_command "yum install net-tools.x86_64 -y"
exec_command "netstat -antup | grep -i 389"
exec_command "LDAPPWD=`slappasswd -s Alfa1234 -h {SSHA}`"
#exec_command "sed -i \"s-\(proxy=\)\(.*\)-\1$CLUSTER_PROXY-g\" $YUM_CONF_FILE"
#exec_command "sed -i \"s-\(olcRootPW:\)-\1$LDAPPWD-g\" db.ldif"
exec_command "sed -i -e \"s/\(olcRootPW:\)\(\.+\)/\1$LDAPPWD/\" db.ldif"
exec_command "ldapmodify -Y EXTERNAL  -H ldapi:/// -f db.ldif"
exec_command "ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif"
#exec_command "openssl req -new -x509 -nodes -out /etc/openldap/certs/quipuldapcert.pem -keyout /etc/openldap/certs/quipuldapkey.pem -days 365"
exec_command "cp ../certs/* /etc/openldap/certs/"
exec_command "chown -R ldap:ldap /etc/openldap/certs/*.pem"
exec_command "ldapmodify -Y EXTERNAL -H ldapi:/// -f certs.ldif"
exec_command "slaptest -u"
exec_command "cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG"
exec_command "chown ldap:ldap /var/lib/ldap/*"
exec_command "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif"
exec_command "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif"
exec_command "ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif"
exec_command "ldapadd -x -w Alfa1234 -D \"cn=ldapadm,dc=quipu,dc=local\" -f base.ldif"
#ldapadd -x -w Alfa1234 -D "cn=ldapadm,dc=quipu,dc=local" -f labdac.ldif
#ldappasswd -s labdac -w Alfa1234 -D "cn=ldapadm,dc=quipu,dc=local" -x "uid=labdac,ou=People,dc=quipu,dc=local"
echo ""
echo "Instalando ldap client"
exec_command "yum install -y openldap-clients nss-pam-ldapd"
exec_command "authconfig --enableldap --enableldapauth --ldapserver=admnode --ldapbasedn=\"dc=quipu,dc=local\" --enablemkhomedir --update"
exec_command "systemctl restart nslcd"
echo ""

echo "Instalando ganglia"
#exec_command "cd ../ganglia"
exec_command "yum install freetype-devel rpm-build php httpd libpng-devel libart_lgpl-devel python-devel pcre-devel autoconf automake libtool expat-devel rrdtool-devel apr-devel gcc-c++ make pkgconfig -y"
exec_command "yum install libconfuse -y"
exec_command "yum install libconfuse-devel -y"
exec_command "yum install ../ganglia/*.rpm -y"
exec_command "cp ../ganglia/gmetad.conf /etc/ganglia/"
#vim gmetad.conf
#vim /etc/ganglia/gmond.conf
exec_command "cp ../ganglia/gmond.conf /etc/ganglia/"
#wget http://downloads.sourceforge.net/project/ganglia/ganglia%20monitoring%20core/3.1.1%20%28Wien%29/ganglia-web-3.1.1-1.noarch.rpm -O ganglia-web-3.1.1-1.noarach.rpm
#exec_command "cd ../ganglia-web"
exec_command "yum install -y ../ganglia-web/ganglia-web-3.1.1-1.noarch.rpm"
#exec_command "yum install -y ../ganglia-web/ganglia-web-3.1.1-1.noarach.rpm"
exec_command "sed -i -e \"s/\(SELINUX=\)\(enforcing\)/\1disabled/\" /etc/sysconfig/selinux"
#reboot
exec_command "systemctl enable httpd"
exec_command "systemctl enable gmetad"
exec_command "systemctl enable gmond"
exec_command "systemctl start httpd"
exec_command "systemctl start gmetad"
exec_command "systemctl start gmond"
echo ""
echo "Instalando SlurmWeb"
exec_command "yum install -y mod_wsgi httpd-devel python-ldap python-redis dejavu-sans-mono-fonts clustershell python-flask Cython npm"
exec_command "git clone -b 17.02.0 https://github.com/PySlurm/pyslurm.git && cd pyslurm && python setup.py build && python setup.py install"
exec_command "git clone https://github.com/clusterfiuba/slurm-web.git"
exec_command "cd slurm-web"
exec_command "tar -xvzf slurm-web-release.tgz"
exec_command "cd release"
exec_command "cp -fR  usr/share/slurm-web /usr/share"
exec_command "chmod 755 -R /usr/share/slurm-web"
exec_command "cp -fR  usr/share/slurm-web /usr/share"
exec_command "chmod 755 -R /usr/share/slurm-web"
exec_command "cp -fR  javascript /usr/share"
exec_command "chmod 755 -R /usr/share/javascript"
exec_command "cp -fR etc/slurm-web /etc"
exec_command "chmod 755 -R /etc/slurm-web"
exec_command "cp -fR etc/httpd/conf.d/* /etc/httpd/conf.d/"
exec_command "chmod 755 -R /etc/httpd/conf.d/*"
exec_command "systemctl restart httpd"
echo ""
echo "Instalando git_service"
#exec_command "git clone https://github.com/clusterfiuba/scripts.git"
#exec_command "cd scripts/git_service && ./install_git_service.sh -d /root"
#exec_command "echo \"PULL_TIME=3600\" > /etc/conf.d/git_service"
#exec_command "echo \"GITHUB_URI=https://github.com/clusterfiuba/quipu.git\" >> /etc/conf.d/git_service"
#exec_command "echo \"GITHUB_USER=clusterfiuba\" >> /etc/conf.d/git_service"
#exec_command "echo \"GITHUB_PASSWORD=Alfa1234\" >> /etc/conf.d/git_service"
#exec_command "echo \"WORKING_DIRECTORY=/root/quipu\" >> /etc/conf.d/git_service"
#exec_command "echo \"USER_HOME=/root\" >> /etc/conf.d/git_service"
#exec_command "systemctl enable git_service"
#exec_command "systemctl start git_service"
echo ""
echo "Instalando nfs server"
exec_command "yum install nfs-utils -y"
exec_command "mkdir /scratch"
exec_command "cp ../nfs/exports /etc/exports"
exec_command "exportfs -a"
echo ""
