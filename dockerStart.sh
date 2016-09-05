#!/bin/bash

parse(){
	msg="- $1 \n - Numero de argumentos invalido"
	msg="$msg \n\n dockerStart [options]"
	msg="$msg \n 	1) -r: run or -i: install"
	msg="$msg \n 	2) -a: all, -s: site, -h: hodeline, -e: secure"
	msg="\n $msg \n"
	printError "$msg"
}

printError(){
	shopt -s xpg_echo
	echo $1
	exit
}

printWarning(){
	shopt -s xpg_echo
	echo $1
}

printFinalHelp(){
	shopt -s xpg_echo
	printf "${GREEN}"
	hostConfig="docker inspect --format='{{.Name}}  {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containers"
	echo "\n Sus servidores se crearon con la siguiente configuracion"
	eval $hostConfig

	echo "\nPara ingresar a sus servidores ejecute los siguientes comandos:"
	command="docker inspect --format='{{.Name}}:$ docker exec -it {{.Config.Hostname}} bash' $i $containers"
	eval $command
	echo "\nLos servidores site y secure cuentan con certificaciones SSL (opcional)\nruta certificados:\n"
	echo "/- SSLCertificateFile /etc/pki/tls/certs/certificate.crt\n/- SSLCertificateKeyFile /etc/pki/tls/private/certificate.key"
	printf "${NC}"
}
# Instala el entorno indicado
installEnviroments(){

	# Validando si es necesario el reinicio del equipo	
	if [ ! -z $REINICIO ] && $REINICIO; then
		printf "${RED}Debe reiniciar el equipo para que tome los cambios necesarios.\nDesea reiniciarlo en este momento [y/n]:${NC}"
		read REINICIOUSER
		if [ !  -z $REINICIOUSER ] && [ "$REINICIOUSER" == "y" ] || [ "$REINICIOUSER" == "Y" ] ; then
			echo "Reiniciando equipo ..."
			reboot
		else
			exit
		fi
	fi

	shopt -s xpg_echo
	# Reiniciamos el servicio docker
	sudo service docker restart

	echo "\nInstalando entornos ..."	
	if [ ! -z $ENVSITE ] && $ENVSITE; then
		imageName="sitep"
		containerName="el_sites"
		deleteChildImageByName $imageName $containerName
		pullImageByName "site"
		# Construye la caja del site
		echo " \n\n\-Instalando entorno de site ..."	
		docker build -t jgomez17/centos-php54:${imageName} -f dockerPromosdecameron/DockerFile .
	fi

	if [ ! -z $ENVHODELINE ] && $ENVHODELINE; then
		imageName="hodelinep"
		containerName="hodeline"
		deleteChildImageByName $imageName $containerName
		pullImageByName "balancer"
		# Construye la caja del site
		echo " \n\n\-Instalando entorno de hodeline ..."	
		docker build -t jgomez17/centos-php54:${imageName} -f dockerHodelineweb/DockerFile .
	fi

	if [ ! -z $ENVSECURE ] && $ENVSECURE; then
		imageName="securep"
		containerName="el_secure"
		deleteChildImageByName $imageName $containerName
		pullImageByName "secure"
		# Construye la caja del site
		echo " \n\n\-Instalando entorno de secure ..."	
		docker build -t jgomez17/centos-php54:${imageName} -f dockerSecure/DockerFile .
	fi

}
# Arranca entornos indicados
runEnviroments(){
	shopt -s xpg_echo
	echo "\nArrancando entornos ..."
	msg="no es un directorio valido! Verifique las rutas en su archivo de configuracion [exit]"
	msgFile="no es un archivo valido! Verifique las rutas en su archivo de configuracion [exit]"
	
	if [ ! -z $ENVSECURE ] && $ENVSECURE; then
        # Construye la caja del site
        echo " \n\-Corriendo entorno de secure ..."
		containerName="el_secure"
		containers="$containers $containerName"
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		# Validando el directorio principal
		if [ ! -d $RUTA_SECURE ] || [ -z $RUTA_SECURE ] ; then
			printWarning " \- RUTA_SECURE ($RUTA_SECURE) $msg"
		else
			RUTA_SECURE="-v $RUTA_SECURE:/var/www/html/securewebgds:rw"
		fi
		if [ ! -d $RUTA_AMADEUS ] || [ -z $RUTA_AMADEUS ] ; then
			printWarning " \- RUTA_AMADEUS ($RUTA_AMADEUS) $msg"
		else
			RUTA_AMADEUS="-v $RUTA_AMADEUS:/var/www/html/amadeusdecameron:rw"
		fi
		if [ ! -d $RUTA_PNP ] || [ -z $RUTA_PNP ] ; then
			printWarning " \- RUTA_PNP ($RUTA_PNP) $msg"
		else
			RUTA_PNP="-v $RUTA_PNP:/var/www/html/pnpwebservice:rw"
		fi
		# Detiene contenedores del site existentes
		if [ ! -z $containerId ] ; then
			stopContainerByName $containerName
		fi
		echo " \-Creando contenedor ($containerName)"
                command="docker run -dt --name $containerName $RUTA_SECURE $RUTA_AMADEUS $RUTA_PNP jgomez17/centos-php54:securep"
		eval $command
		
		containerIdSecure=$(docker inspect --format='{{.Id}}' $i $containerName)
		if [ ! -z $containerIdSecure ] ; then
                	echo "\n \-Contenedor ($containerName) creado con id ($containerIdSecure) [done]"
			service="docker exec -it $containerIdSecure /bin/bash -c 'service httpd start'"
			eval $service
			principalSecure=$(cat dockerSecure/balancer.conf | jq ".principal" | sed 's/"//g')
			principalAmadeus=$(cat dockerSecure/balancer.conf | jq ".amadeus" | sed 's/"//g')
			principalPnp=$(cat dockerSecure/balancer.conf | jq ".pnp" | sed 's/"//g')
			service="docker exec -it $containerIdSecure /bin/bash -c 'service httpd start'"
			eval $service
			# Se generan Hosts en los container
			command="docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containerName"	
			ipcontainerSecure=$(eval $command)
			if [ ! -z $principalSecure ] ; then
				hostsSecure="docker exec -it $containerIdSecure bash -c \"echo '$ipcontainerSecure	$principalSecure' >> /etc/hosts\""
				eval $hostsSecure
				if ! grep -q "\s${principalSecure}$" /etc/hosts ; then 
					sudo -- sh -c "echo '$ipcontainerSecure	$principalSecure' >> /etc/hosts"
				else
					# si existe lo modificamos a la nueva ip
					sudo cp /etc/hosts /etc/hosts_bk
					#sudo cat /etc/hosts_bk | sed "s/.*$principalSecure/$ipcontainerSecure\t$principalSecure/g" > /etc/hosts
					sudo -- sh -c "cat /etc/hosts_bk | sed 's/.*$principalSecure/$ipcontainerSecure\t$principalSecure/g' > /etc/hosts"
				fi
			fi		
 			
		fi
    fi
	
	if [ ! -z $ENVHODELINE ] && $ENVHODELINE; then
                # Construye la caja del site
                echo " \n\-Corriendo entorno de hodeline ..."        
		containerName="hodeline"
		containers="$containers $containerName"
		containerId=$(docker inspect --format='{{.Id}}' $i  $containerName)
		if [ ! -d $RUTA_HODELINE ] ; then
			printError "\n\- RUTA_HODELINE ($RUTA_HODELINE) $msg"
		fi
		# Detiene contenedores del site existentes
		if [ ! -z $containerId ] ; then
			stopContainerByName $containerName
		fi

		if [ ! -d $RUTA_TEMPORAL ] ; then
			printError "\n\- ($RUTA_TEMPORAL) $msg"
		fi
		echo " \-Creando contenedor ($containerName)"
                command="docker run -dti --name $containerName -v $RUTA_HODELINE:/var/www/html/decameron:rw -v $RUTA_TEMPORAL:/var/www/temporal:rw jgomez17/centos-php54:hodelinep"
		eval $command
		
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		if [ ! -z $containerId ] ; then
                	echo "\n \-Contenedor ($containerName) creado con id ($containerId) [done]"
			principalHW=$(cat dockerHodelineweb/balancer.conf | jq ".principal" | sed 's/"//g')
			node1HW=$(cat dockerHodelineweb/balancer.conf | jq ".sites.nodo1" | sed 's/"//g')
			node2HW=$(cat dockerHodelineweb/balancer.conf | jq ".sites.nodo2" | sed 's/"//g')
 			service="docker exec -it $containerId /bin/bash -c 'service httpd start'"
			eval $service
			# Se generan Hosts en los container
			command="docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containerName"	
			ipcontainerHW=$(eval $command)
			hostsHW="docker exec -it $containerId bash -c \"echo '$ipcontainerHW	$node1HW' >> /etc/hosts\""
			eval $hostsHW
			hostsHW="docker exec -it $containerId bash -c \"echo '$ipcontainerHW	$node2HW' >> /etc/hosts\""
			eval $hostsHW
			# si no existe el hosts lo agregamos
			if ! grep -q "\s${principalHW}$" /etc/hosts ; then 
				sudo -- sh -c "echo '$ipcontainerHW	$principalHW' >> /etc/hosts"
			else
				# si existe lo modificamos a la nueva ip
				sudo cp /etc/hosts /etc/hosts_bk
				#sudo cat /etc/hosts_bk | sed "s/.*$principalHW/$ipcontainerHW\t$principalHW/g" > /etc/hosts
				sudo -- sh -c "cat /etc/hosts_bk | sed 's/.*$principalHW/$ipcontainerHW\t$principalHW/g' > /etc/hosts"
			fi
			if [ ! -z $principalSecure ] ; then
				hostsHW="docker exec -it $containerId bash -c \"echo '$ipcontainerSecure	$principalSecure' >> /etc/hosts\""
				eval $hostsHW
				hostsHW="docker exec -it $containerIdSecure bash -c \"echo '$ipcontainerHW	$principalHW' >> /etc/hosts\""
				eval $hostsHW	
			fi
			
		fi
    fi
        
	if [ ! -z $ENVSITE ] && $ENVSITE; then
                # Construye la caja del site
                echo " \n\-Corriendo entorno de site ..."
		containerName="el_sites"
		containers="$containers $containerName"
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		# Validando el directorio principal
		if [ ! -d $RUTA_PARTICULARES ] || [ -z $RUTA_PARTICULARES ] ; then
			printWarning " \- RUTA_PARTICULARES ($RUTA_PARTICULARES) $msg"
		else
			RUTA_PARTICULARES="-v $RUTA_PARTICULARES:/var/www/html/www.decameron.com:rw"
		fi
		if [ ! -d $RUTA_AGENCIAS ] || [ -z $RUTA_AGENCIAS ] ; then
			printWarning " \- RUTA_AGENCIAS ($RUTA_AGENCIAS) $msg"
		else
			RUTA_AGENCIAS="-v $RUTA_AGENCIAS:/var/www/html/promosdecameron:rw"
		fi
		if [ ! -d $RUTA_TEMPORAL ] ; then
			printError "\n\- ($RUTA_TEMPORAL) $msg"
		fi
		# Detiene contenedores del site existentes
		if [ ! -z $containerId ] ; then
			stopContainerByName $containerName
		fi
		echo " \-Creando contenedor ($containerName)"
                command="docker run -dt --name $containerName $RUTA_PARTICULARES -v $RUTA_TEMPORAL:/var/www/temporal:rw $RUTA_AGENCIAS jgomez17/centos-php54:sitep"
		eval $command
		
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		if [ ! -z $containerId ] ; then
                	echo "\n \-Contenedor ($containerName) creado con id ($containerId) [done]"
			principalSite=$(cat dockerPromosdecameron/balancer.conf | jq ".principal" | sed 's/"//g')
			principalAgencias=$(cat dockerPromosdecameron/balancer.conf | jq ".agencias" | sed 's/"//g')
			node1Site=$(cat dockerPromosdecameron/balancer.conf | jq ".sites.nodo1" | sed 's/"//g')
			node2Site=$(cat dockerPromosdecameron/balancer.conf | jq ".sites.nodo2" | sed 's/"//g')
 			service="docker exec -it $containerId /bin/bash -c 'service httpd start'"
			eval $service
			# Se generan Hosts en los container
			command="docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containerName"	
			ipcontainerSite=$(eval $command)
			if [ ! -z $node1Site ] ; then
				hostsSite="docker exec -it $containerId bash -c \"echo '$ipcontainerSite	$node1Site' >> /etc/hosts\""
				eval $hostsSite
			fi
			if [ ! -z $node2Site ] ; then
				hostsSite="docker exec -it $containerId bash -c \"echo '$ipcontainerSite	$node2Site' >> /etc/hosts\""
				eval $hostsSite
			fi
			if [ ! -z $principalHW ] ; then
				hostsSite="docker exec -it $containerId bash -c \"echo '$ipcontainerHW		$principalHW' >> /etc/hosts\""
				eval $hostsSite
			fi
			# si no existe el hosts lo agregamos
			if ! grep -q "\s${principalSite}$" /etc/hosts ; then 
				sudo -- sh -c "echo '$ipcontainerSite	$principalSite' >> /etc/hosts"
			else
				# si existe lo modificamos a la nueva ip
				sudo cp /etc/hosts /etc/hosts_bk
				#sudo cat /etc/hosts_bk | sed "s/.*$principalSite/$ipcontainerSite\t$principalSite/g" > /etc/hosts
				sudo -- sh -c "cat /etc/hosts_bk | sed 's/.*\t$principalSite/$ipcontainerSite\t$principalSite/g' > /etc/hosts"
			fi
			if [ ! -z $principalAgencias ] ; then
				if ! grep -q "\s${principalAgencias}$" /etc/hosts ; then 
					sudo -- sh -c "echo '$ipcontainerSite	$principalAgencias' >> /etc/hosts"
				else
					# si existe lo modificamos a la nueva ip
					sudo cp /etc/hosts /etc/hosts_bk
					#sudo cat /etc/hosts_bk | sed "s/.*$principalAgencias/$ipcontainerSite\t$principalAgencias/g" > /etc/hosts
					sudo -- sh -c "cat /etc/hosts_bk | sed 's/.*\t$principalAgencias/$ipcontainerSite\t$principalAgencias/g' > /etc/hosts"
				fi
			fi
		fi

        fi
}

stopContainerByName(){
	# Detiene contenedores del site existentes
	echo " \-Parando contenedor ($1)"
	docker stop $(docker inspect --format='{{.Id}}' $i $1)
	echo " \-Eliminando contenedor ($1)"
	docker rm $(docker inspect --format='{{.Id}}' $i $1)
}

deleteChildImageByName(){
	imageName=$1
	containerName=$2
	imageSecureId=$(docker images --format '{{.ID}};{{.Tag}}' | grep $imageName | cut -d ';' -f 1)
	if [ ! -z $imageSecureId ]; then
		stopContainerByName $containerName
		printf "${RED}"
		echo "Eliminando imagen ... "
		command="docker rmi $imageSecureId"
		eval $command
		echo " [ok]\n"
		printf "${NC}"
	fi
}

pullImageByName(){
	imagePullName=$1
	printf "${BLUE}Actualizando imagen $imagePullName\n"
	command="docker pull jgomez17/centos-php54:${imagePullName}"
	echo $command
	eval $command
	printf " [ok]${NC}"
}


if test "$(($#))" -le 0 ; then
	parse
fi

for param in "$@"
do
case $param in
	-i)
		INSTALL=true
	;;
	-r)
		RUN=true
	;;
	-a)
		ENVSITE=true
		ENVHODELINE=true
		ENVSECURE=true
	;;
	-s)
		ENVSITE=true
	;;
	-h)
		ENVHODELINE=true
	;;
	-e)
		ENVSECURE=true
	;;
	*)
	;;
esac
done
#Valido que tenga instalado jq para poder procesar la informacion de configuracion
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
if [ -x /usr/bin/jq ] || [ -x /usr/sbin/jq ]; then
	echo "Tienes instalado JQ para archivos json"
else
	echo "Instalado JQ para archivos json..."
	if [ -f /etc/debian_version ]; then
		sudo apt-get install -y jq
	elif [ -f /etc/redhat-release ]; then
		printf "${RED}"
		sudo yum install -y jq
		printf "${NC}"
	fi
fi
#Valido que tenga instalado docker de no ser asi se instalara
if [ -x /usr/bin/docker ] || [ -x /usr/sbin/docker ]; then
	echo "Tienes Docker Instalado..."
else
	echo "Instalando Docker..."
	printf "${RED}"
	curl -sSL https://get.docker.com/ | sh
	printf "${NC}"
	if [ -f /etc/debian_version ]; then
		sudo chkconfig docker on
	elif [ -f /etc/redhat-release ]; then
		sudo systemctl enable docker
	fi
fi

if ! groups | grep -q docker; then
	sudo usermod -a -G docker ${USER}
	REINICIO=true
fi

ps -ef | grep 'docker daemon\|dockerd' | grep -v grep
if [ $?  -eq "0" ] ; then
	echo " \-El proceso esta corriendo" 
else
	echo " \-El proceso no esta corriendo. Intentando iniciar el servicio ..." && service docker start
	ps -ef | grep 'docker daemon\|dockerd' | grep -v grep
	[ $?  -eq "0" ] && echo " \-El proceso esta corriendo" || printError "No fue posible iniciar el servicio. Intentelo nuevamente"
fi

# Valido parametros requeridos
if [ -z $ENVSITE ] && [ -z $ENVHODELINE ] && [ -z $ENVSECURE ]; then
        parse "Especifique el entorno a trabajar"
fi
# Valida la ruta del archivo de configuracion
#echo "Digite la ruta del archivo de configuracion que se va a ejecutar:"
#read pathConfiguration
pathConfiguration="./configuracion.conf"

if [ ! -f $pathConfiguration ] ; then
	printError "El archivo de configuración no existe! [exit]"
fi
# Obteniendo variables del archivo de configuracion
IFS="="
while read -r name value
do
	var="$name"
	eval "${var}='${value//\"/}'"
done < $pathConfiguration

# Validando opciones enviadas por consola
if [ ! -z $INSTALL ] || [ ! -z $RUN ] ; then
	if [ ! -z $INSTALL ] && $INSTALL ; then
		installEnviroments
	fi

	if [ ! -z $RUN ] && $RUN ; then
		runEnviroments
		printFinalHelp
	fi
fi
