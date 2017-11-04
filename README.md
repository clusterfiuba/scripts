# Scripts para el despliegue de nodos de QUIPU.

Aqui se encuentra el juego de scripts para realizar la instalación de las herramientas necesarias para el despliegue de un nodo administrador o un nodo de cómputo para QUIPU.

### Instalacion de un nodo administrador o de cómputo
Ejecutar los siguientes scripts:
1. network/net_config.sh
2. nfs/nfs_init.sh
3. tools/install_tools.sh
4. cd slurm && node_install.sh

### Opcional

##### Servicio de GIT
Si se desea instalar el servicio de GIT en el nodo administrador que actualiza la IP contra un repositorio GIT se debe ejecutar:

cd git_service && install_git_service.sh

##### Gerris
Si desea instalar Gerris, se debe ejecutar el siguiente comando:

cd gerris && tar -xvzf gerris.tar.gz && cd gerris && gerris.sh

### Parametros de ejecución de los scripts
A continuación se muestran los parametros de ejecución que se le deben proveer a algunos de los scripts mencionados anteriormente.

*net_config.sh*

	NAME
		net_config

	SYNOPSIS
		net_config -t [TYPE] -a [NETWORK_ADAPTER_NAME] -i [IP_ADDRESS] -n [NODE_NAME] -g [GATEWAY]

	DESCRIPTION
		-t [TYPE]
			type of node in the cluster: admnode or cnode.

		-a [NETWORK_ADAPTER_NAME]
			name of the netcard device which result of ip addr command. Example enp63s0

		-i [IP_ADDRESS]
			ip of the node in the internal network of cluster.

		-n [NODE_NAME]
			name of the node in the cluster. Example admnode, cnode1, etc.

		-g [GATEWAY]
			in the case of cnode set the ip of admnode otherwise set -

*nfs_init.sh*

	NAME
		nfs_init

	SYNOPSIS
		nfs_init -l [LOCAL_DIR] -r [REMOTE_DIR] -a [ADMNODE_IP]

	DESCRIPTION
		-l [LOCAL_DIR]
			name of local directory where mount the remote directory.

		-r [REMOTE_DIR]
			name of remote directory to mount

		-a [ADMNODE_IP]
			ip of admnode.

*node_install.sh*

	NAME
		node_install

	SYNOPSIS
		node_install -t [TYPE] -n [NTP_SYNC_NODE]

	DESCRIPTION
		-t [TYPE]
			type of node in the cluster: admnode or cnode.

		-n [NTP_SYNC_NODE]
			IP or name of the admnode with which to synchronize the date and time.
			If this is the admnode, enter -

*install_git_service.sh*

	NAME
		install_git_service

	SYNOPSIS
		install_git_service.sh -d [INSTALATION DIRECTORY]

	DESCRIPTION
		-d [INSTALATION DIRECTORY]
			directory where install service script

	CHEAT SHEET
		Iniciar el servicio
			systemctl start git_service.service
		Detener el servicio
			systemctl stop git_service.service
		Consultar el estado del servicio
			systemctl status git_service.service
		Iniciar el servicio en el arranque del equipo
			systemctl enable git_service.service
		Detener el servicio en el arranque del equipo
			systemctl disable git_service.service
		Consultar los logs del dia del servicio
			journalctl -u nginx.service -u php-fpm.service --since today

