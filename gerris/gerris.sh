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

########## Environment variables ##########
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

########## Update yum ##########
echoBold "Actualizando yum"
exec_command "yum update -y"

########## Install dependencies ##########
echoBold "Instalando y actualizando dependencias"
exec_command "yum groupinstall \"Development Tools\" -y"
exec_command "yum groupinstall \"Compatibility Libraries\" -y"

exec_command "yum install startup-notification-devel-0.12-8.el7.i686 startup-notification-devel-0.12-8.el7.x86_64 ncurses-devel zlib-devel texinfo gtk2-devel qt-devel tcl-devel tk-devel kernel-headers kernel-devel fftw-devel-3.3.3-8.el7.i686 fftw-devel-3.3.3-8.el7.x86_64 which -y"
exec_command "yum install packages/pangox-compat-0.0.2-2.el7.x86_64.rpm -y && yum install packages/pangox-compat-devel-0.0.2-2.el7.x86_64.rpm -y"


# install gtklext
exec_command "tar -xvzf packages/gtkglext-1.2.0.tar.gz && cd gtkglext-1.2.0 && ./configure && make && make install"

# install openmpi
cd ..
exec_command "tar -xvzf packages/openmpi-3.0.0.tar.gz && cd openmpi-3.0.0 && ./configure && make && make install"

# install hypre
cd ..
exec_command "tar -xvzf packages/hypre-2.11.2.tar.gz && cd hypre-2.11.2/src && ./configure make && make install"

# install ffmpeg
cd ../../
exec_command "tar -xvzf packages/ffmpeg-3.4.tar.gz && cd ffmpeg-3.4 && ./configure --disable-x86asm && make && make install"

########## Install Gerris ##########
# install gts
exec_command "cd ../ && unzip packages/gts-stable.zip"
exec_command "cd gts-stable && sh autogen.sh && automake --add-missing && ./configure && make && make install"

# install gerris
exec_command "cd ../ && unzip packages/gerris-stable.zip"
exec_command "cd gerris-stable && sh autogen.sh && automake --add-missing && touch test-driver && make && make install"

# install Pablo gerris
exec_command "cd ../Gerris-ControllerModule/gerris-stable && touch test-driver && sh autogen.sh && make && make install"
