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
	hostConfig="docker inspect --format='{{.Name}}  {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i $containers"
	echo "\n Sus servidores se crearon con la siguiente configuracion"
	eval $hostConfig

	echo "\nPara ingresar a sus servidores ejecute los siguientes comandos:"
	command="docker inspect --format='docker exec -it {{.Config.Hostname}} bash' $i $containers"
	eval $command
	echo "\n"
}
# Instala el entorno indicado
installEnviroments(){
	shopt -s xpg_echo
	echo "\nInstalando entornos ..."	
	if [ ! -z $ENVSITE ] && $ENVSITE; then
		# Construye la caja del site
		echo " \n\n\-Instalando entorno de site ..."	
		docker build -t jgomez17/centos-php54:site -f dockerPromosdecameron/DockerFile .
	fi

	if [ ! -z $ENVHODELINE ] && $ENVHODELINE; then
		# Construye la caja del site
		echo " \n\n\-Instalando entorno de hodeline ..."	
		docker build -t jgomez17/centos-php54:hodeline -f dockerHodelineweb/DockerFile .
	fi

	if [ ! -z $ENVSECURE ] && $ENVSECURE; then
		# Construye la caja del site
		echo " \n\n\-Instalando entorno de secure ..."	
		docker build -t jgomez17/centos-php54:secure -f dockerSecure/DockerFile .
	fi
}
# Arranca entornos indicados
runEnviroments(){
	shopt -s xpg_echo
	echo "\nArrancando entornos ..."
	msg="no es un directorio valido! Verifique las rutas en su archivo de configuracion [exit]"
	msgFile="no es un archivo valido! Verifique las rutas en su archivo de configuracion [exit]"
	
	if [ ! -f ${RUTA_CRT_HW} ] ; then
		printError "\n\- ($RUTA_CRT_HW) $msgFile"
	fi
	if [ ! -f ${RUTA_KEY_HW} ] ; then
		printError "\n\- ($RUTA_KEY_HW) $msgFile"
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
			RUTA_AGENCIAS="-v $RUTA_AGENCIAS:/var/www/html/promos-decameron:rw"
		fi
		if [ ! -d $RUTA_TEMPORAL ] ; then
			printError "\n\- ($RUTA_TEMPORAL) $msg"
		fi
		# Detiene contenedores del site existentes
		if [ ! -z $containerId ] ; then
			echo " \-Parando contenedor ($containerName)"
			docker stop $(docker inspect --format='{{.Id}}' $i $containerName)
			echo " \-Eliminando contenedor ($containerName)"
			docker rm $(docker inspect --format='{{.Id}}' $i $containerName)
		fi
		echo " \-Creando contenedor ($containerName)"
                command="docker run -dt --name $containerName $RUTA_PARTICULARES -v $RUTA_TEMPORAL:/var/www/temporal/:rw -v $RUTA_CRT_HW:/var/www/html/securep.decameron.com.crt:rw -v $RUTA_KEY_HW:/var/www/html/securep.decameron.com.key:rw $RUTA_AGENCIAS jgomez17/centos-php54:site"
		eval $command
		
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		if [ ! -z $containerId ] ; then
                	echo "\n \-Contenedor ($containerName) creado con id ($containerId) [done]"
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
			echo " \-Parando contenedor ($containerName)"
			docker stop $(docker inspect --format='{{.Id}}' $i $containerName)
			echo " \-Eliminando contenedor ($containerName)"
			docker rm $(docker inspect --format='{{.Id}}' $i $containerName)
		fi
		echo " \-Creando contenedor ($containerName)"
                command="docker run -dt --name $containerName -v $RUTA_HODELINE:/var/www/html/decameron:rw -v $RUTA_CRT_HW:/var/www/html/securep.decameron.com.crt:rw -v $RUTA_KEY_HW:/var/www/html/securep.decameron.com.key:rw jgomez17/centos-php54:hodeline"
		eval $command
		
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		if [ ! -z $containerId ] ; then
                	echo "\n \-Contenedor ($containerName) creado con id ($containerId) [done]"
		fi
        fi

        if [ ! -z $ENVSECURE ] && $ENVSECURE; then
                # Construye la caja del site
                echo " \n\-Corriendo entorno de site ..."
		containerName="secure"
		containers="$containers $containerName"
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		# Validando el directorio principal
		if [ ! -d $RUTA_SECURE ] || [ -z $RUTA_SECURE ] ; then
			printWarning " \- RUTA_SECURE ($RUTA_SECURE) $msg"
		else
			RUTA_SECURE="-v $RUTA_SECURE:/var/www/html/secure-web-gds:rw"
		fi
		if [ ! -d $RUTA_AMADEUS ] || [ -z $RUTA_AMADEUS ] ; then
			printWarning " \- RUTA_AMADEUS ($RUTA_AMADEUS) $msg"
		else
			RUTA_AMADEUS="-v $RUTA_AMADEUS:/var/www/html/amadeusdecameron:rw"
		fi
		if [ ! -d $RUTA_PNP ] || [ -z $RUTA_PNP ] ; then
			printWarning " \- RUTA_PNP ($RUTA_PNP) $msg"
		else
			RUTA_PNP="-v $RUTA_PNP:/var/www/html/pnp-webservice:rw"
		fi
		# Detiene contenedores del site existentes
		if [ ! -z $containerId ] ; then
			echo " \-Parando contenedor ($containerName)"
			docker stop $(docker inspect --format='{{.Id}}' $i $containerName)
			echo " \-Eliminando contenedor ($containerName)"
			docker rm $(docker inspect --format='{{.Id}}' $i $containerName)
		fi
		echo " \-Creando contenedor ($containerName)"
                command="docker run -dt --name $containerName $RUTA_SECURE $RUTA_AMADEUS $RUTA_PNP -v $RUTA_CRT_HW:/var/www/html/securep.decameron.com.crt:rw -v $RUTA_KEY_HW:/var/www/html/securep.decameron.com.key:rw jgomez17/centos-php54:secure"
		eval $command
		
		containerId=$(docker inspect --format='{{.Id}}' $i $containerName)
		if [ ! -z $containerId ] ; then
                	echo "\n \-Contenedor ($containerName) creado con id ($containerId) [done]"
		fi
        fi
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
#Valido que tenga instalado docker de no ser asi se instalara
if [ -x /usr/bin/docker ] || [ -x /usr/sbin/docker ]; then
	echo "Tienes Docker Instalado..."
else
	curl -sSL https://get.docker.com/ | sh
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
