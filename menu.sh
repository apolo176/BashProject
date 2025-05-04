#!/usr/bin/bash
#Prueba
function empaquetaycomprimeFicherosProyecto()
{
	cd /home/$USER/formulariocitas
	tar cvzf  /home/$USER/formulariocitas.tar.gz app.py script.sql  .env requirements.txt templates/*
}
function eliminarMySQL()
{
	#Para el servicio
	sudo systemctl stop mysql.service
	#Elimina los paquetes +ficheros de configuración + datos
	sudo apt purge mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
	#servidor MySQL se desinstale completamente sin dejar archivos de residuos.
	sudo apt autoremove
	#Limpia la cache
	sudo apt autoclean
	#Para cerciorarnos de que queda todo limpio:
	#Eliminar los directorios de datos de MySQL:
	sudo rm -rf /var/lib/mysql
	#Eliminar los archivos de configuración de MySQL:
	sudo rm -rf /etc/mysql/
	#Eliminar los logs
	sudo rm -rf /var/log/mysql
}

function crearNuevaUbicacion()
{
	if [ -d /var/www/formulariocitas ]
	then
		echo -e "Borrando el contenido del direcctorio...\n"
		sudo rm -rf /var/www/formulariocitas
	fi
	echo "Creando directorio..."
	sudo mkdir -p /var/www/formulariocitas
	echo "Cambiando permisos del directorio..."
	sudo chown -R $USER:$USER /var/www/formulariocitas
	echo ""
	read -p "PULSA ENTER PARA CONTINUAR..."
}
function copiarFicherosProyectoNuevaUbicacion()
{
	tar -xf /home/$USER/formulariocitas.tar.gz -C /var/www/formulariocitas
}
function instalarMySQL()
{
	if dpkg -l | grep -q mysql-server;
	then
		echo "MySQL ya está instalado"
		if ! systemctl status mysql.service > /dev/null 2>&1;
		then
			sudo systemctl start mysql.service
		fi	
		return
	fi
	sudo apt update
	sudo apt install mysql-server
	if ! systemctl status mysql.service > /dev/null 2>&1;
	then
		sudo systemctl start mysql.service
	fi
}
function crearusuariobasesdedatos()
{
	sqlScript="crear_usuario.sql"
	touch "/home/$USER/formulariocitas/$sqlScript"
	echo "CREATE USER 'lsi'@'localhost' IDENTIFIED BY 'lsi';" >> "$sqlScript"
	echo "GRANT CREATE, ALTER, DROP, INSERT, UPDATE, INDEX, DELETE, SELECT,
	REFERENCES, RELOAD ON *.* TO 'lsi'@'localhost' WITH GRANT OPTION;" >>"$sqlScript"
  	echo "FLUSH PRIVILEGES;" >> "$sqlScript"
  	echo "El script se ha creado correctamente"
  	sudo mysql < /home/$USER/formulariocitas/crear_usuario.sql 
  	return
}
function crearbasededatos()
{
	mysql -u lsi -p < /home/$USER/formulariocitas/script.sql 
	return
}
function ejecutarEntornoVirtual()
{
	sudo apt update
	sudo apt -y upgrade
	sudo apt install -y python3-venv python3-dev build-essential libssl-dev libffi-dev python3-setuptools python3-pip
	cd /var/www/formulariocitas
	python3 -m venv venv
	source venv/bin/activate

}

function instalarLibreriasEntornoVirtual()
{
	cd /var/www/formulariocitas
	source venv/bin/activate
	python -m pip install --upgrade pip
	pip install -r requirements.txt
	#kepa activa y desactiva todo el rato
}


function probandotodoconservidordedesarrollodeflask()
{
	python3 /home/$USER/formulariocitas/app.py
}

function instalarNGINX()
{
	if dpkg -s | grep nginx;
	then
		echo "NGINX ya está instalado"
		return	
	fi
	sudo apt update
	sudo apt install nginx
}

function arrancarNGINX()
{
	if  systemctl status nginx.service > /dev/null 2>&1;
	then
		echo "El servicio está en marcha"
		return
	fi
	sudo systemctl start nginx.service
}

#todo no reconoce !dpkg
function testearPuertosNGINX()
{ 
	if !dpkg -s | grep net-tools/etc/nginx/conf.d/;then
		sudo apt install net-tools
	fi
	sudo netstat -anp | grep nginx
	
}

function visualizarIndex()
{ 
	firefox http://localhost
}
#todo faltan comprobaciones y ademas faltan los sudos
function personalizarIndex()
{ 
	sudo > /var/www/html/index.nginx-debian.html
	sudo mv /var/www/html/index.nginx-debian.html /var/www/html/index.html
	sudo echo '<!DOCTYPE html>' > /var/www/html/index.html
	sudo echo '  <html>' >> /var/www/html/index.html
	sudo echo '  <head>' >> /var/www/html/index.html
	sudo echo '<title>NOMBRE DEL GRUPO</title>' >> /var/www/html/index.html
	sudo echo ' </head>' >> /var/www/html/index.html
	sudo echo ' <body>' >> /var/www/html/index.html
	sudo echo '<center>' >> /var/www/html/index.html
	sudo echo '    <h1>NOMBRE DEL GRUPO</h1>' >> /var/www/html/index.html
	sudo echo '</center>' >> /var/www/html/index.html
	sudo echo '' >> /var/www/html/index.html
	sudo echo '<table border="5" bordercolor="red" align="center">' >> /var/www/html/index.html
	sudo echo '    <tr>' >> /var/www/html/index.html
	sudo echo '        <th colspan="3">NOMBRE DEL GRUPO</th>' >> /var/www/html/index.html
	sudo echo '    </tr>' >> /var/www/html/index.html
	sudo echo '    <tr>' >> /var/www/html/index.html
	sudo echo '        <th>Nombre</th>' >> /var/www/html/index.html
	sudo echo '        <th>Apellidos</th>' >> /var/www/html/index.html
	sudo echo '        <th>Foto</th>' >> /var/www/html/index.html
	sudo echo '    </tr>' >> /var/www/html/index.html
	sudo echo '     <tr>' >> /var/www/html/index.html
	sudo echo '        <td>Kepa</td>' >> /var/www/html/index.html
	sudo echo '        <td>Bengoetxea Kortazar</td>' >> /var/www/html/index.html
	sudo echo '        <td border=3 height=100 width=100>Photo1</td>' >> /var/www/html/index.html
	sudo echo '    </tr>' >> /var/www/html/index.html
	sudo echo '</table>' >> /var/www/html/index.html
	sudo echo '<center>' >> /var/www/html/index.html
	sudo echo '    El cabeza de grupo es Kepa Bengoetxea' >> /var/www/html/index.html
	sudo echo '</center>' >> /var/www/html/index.html
	sudo echo '  </body>' >> /var/www/html/index.html
	sudo echo '  </html>' >> /var/www/html/index.html	
}

function instalarGunicorn()
{ 
	cd /var/www/formulariocitas
	source venv/bin/activate
	pip install gunicorn
	#comprobar si esta instalado con pip
}

function configurarGunicorn()
{ 
	cd /var/www/formulariocitas
	source venv/bin/activate
	GunicornFile="wsgi.py"
	t:=ouch "$GunicornFile"
	echo "from app import app">wsgi.py
	echo "if __name__=='__main__':" >> wsgi.py
	echo "	app.run()" >> wsgi.py
	gunicorn --bind localhost:5000 wsgi:app &
	firefox localhost:5000
}

#todo comprobaciones etc...
function pasarPropiedadyPermisos()
{ 
	sudo chown -R www-data:www-data /var/www/formulariocitas
	echo "La propiedad ha sido transferida al <usuario:grupo>: <www-data:www-data>."
	
}

#todo comprobaciones etc...
function crearServicioSystemdFormularioCitas()
{ 
	echo "Creando servicio systemd para formulario de citas..."
	cat <<EOF | sudo tee /etc/systemd/system/formulariocitas.service > /dev/null
	[Unit]
	Description=Gunicorn instance to serve Flask
	After=network.target

	[Service]
	User=www-data
	Group=www-data
	WorkingDirectory=/var/www/formulariocitas
	Environment="PATH=/var/www/formulariocitas/venv/bin"
	ExecStart=/var/www/formulariocitas/venv/bin/gunicorn --bind 127.0.0.1:5000 wsgi:app
	Restart=always

	[Install]
	WantedBy=multi-user.target
EOF
	sudo systemctl daemon-reload
	echo "Servicio creado en /etc/systemd/system/formulariocitas.service "
	sudo systemctl enable formulariocitas
	sudo systemctl start formulariocitas
	echo "Verificando estado del servicio..."
	sleep 1  # Pequeña pausa para dar tiempo al servicio a arrancar

	if systemctl is-active --quiet formulariocitas; then
        	echo "✅ El servicio 'formulariocitas' se ha creado y está activo."
	else
		echo "❌ El servicio 'formulariocitas' no está activo. Revisa los logs con:"
		echo "   sudo journalctl -u formulariocitas -e"
	fi

}

function configurarNginxProxyInverso()
{ 
	local conf_path="/etc/nginx/conf.d/formulariocitas.conf"
	if [ -f "$conf_path" ]; then
		echo "⚠️  El archivo $conf_path ya existe. No se ha hecho ninguna modificación."
	else
		echo "Creando configuración de Nginx para formulario de citas..."
		sudo tee "$conf_path" > /dev/null <<EOF
		server {
		    listen 3128;
		    server_name localhost;
		    location / {
			include proxy_params;
			proxy_pass  http://127.0.0.1:5000;
		    }
		}
EOF
		echo "✅ Configuración creada en $conf_path"
		echo "Recargando Nginx..."
		sudo nginx -t && sudo systemctl reload nginx
	fi
	echo "🔎 Comprobando sintaxis de la configuración de Nginx..."
	if sudo nginx -t; then
		echo "✅ Sintaxis válida. Puede recargar Nginx con la opción 20"

	else
		echo "❌ Error en la configuración de Nginx. No se ha recargado el servicio."
		echo "   Revisa los mensajes anteriores para más detalles."


	fi

}

function cargarFicherosConfiguracionNginx()
{
	sudo systemctl reload nginx
	echo "⚙️ Nginx recargado correctamente con la nueva configuración."

}

function rearrancarNginx()
{ 
	sudo systemctl restart nginx
	echo "🚀 Nginx reiniciado correctamente."
}

function testearVirtualHost()
{ 
	echo "🔎 Vamos a testear el servicio"
	echo "⚠️ En unos segundos se te redigirá al navegador"
	sleep 3
 	firefox http://127.0.0.1:8080
}

function verNginxLogs()
{ 
	tail -10 /var/log/nginx/error.log
}

function copiarServidorRemoto()
{ 
	sudo apt install openssh-service
	sudo systemctl enable ssh
	sudo systemctl start ssh
	echo "Introduce la IP del servidor remoto"
	read ip
	scp menu.sh &USER@&ip:/home/$USER/formulariocitas
	scp formulariocitas.tar.gz $USER@$ip:/home/$USER/formulariocitas
	ssh $USER@$ip
	bash -x menu.sh

}

function controlarIntentosConexionSSH()
{
	echo "Analizando logs de intentos de conexión SSH..."

	# Listar todos los ficheros auth.log* (incluyendo los comprimidos)
	LOGS=$(ls /var/log/auth.log* 2>/dev/null)

	for LOG in $LOGS; do
	if [[ $LOG == *.gz ]]; then
	    zcat "$LOG"
	else
	    cat "$LOG"
	fi
	done | grep "sshd" | grep -E "Failed password|Accepted password" | while read -r LINE; do
		DATE=$(echo "$LINE" | awk '{print $1, $2, $3}')
		STATUS=$(echo "$LINE" | grep -q "Failed password" && echo "fail" || echo "accept")
		USER=$(echo "$LINE" | awk '{for(i=1;i<=NF;i++) if($i=="for") print $(i+1)}')
		echo "\"Status: [$STATUS] Account name: $USER Date: $DATE\""
	done
}

function clonarProyectoGitHub() {
	token="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"
	repo_url="https://$token@github.com/apolo176/BashProject.git"
	read -p "Introduce el directorio destino (ruta absoluta): " destino
	if [ -d "$destino/.git" ]; then
        	echo "El directorio ya contiene un repositorio Git. Ejecutando git pull..."
		cd "$destino"
        	git pull origin main
    	else
        	echo "El directorio no existe o no es un repositorio. Clonando..."
        	mkdir -p "$destino"
        	git clone "$repo_url" "$destino"
    	fi
    	if [ $? -eq 0 ]; then
        	echo "Operación realizada exitosamente en $destino."
    	else
        	echo "Error al realizar la operación. Revisa la URL, los permisos y la configuración."
    	fi
}

function actualizarProyectoGitHub() {
	token="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"
	echo "Introduce esto cuando pida la contraseña $token"
	proyecto="/home/$USER/formulariocitas"

	# Comprobamos si es un repositorio Git
	if [ ! -d "$proyecto/.git" ]; then
		echo "La ruta proporcionada no parece ser un repositorio Git."
		return
	fi

	cd "$proyecto"

	# Preguntar al usuario por su nombre y correo
	#echo "Por favor, introduce tu nombre para el commit:"
	#read -p "Nombre: " nombre
	#echo "Por favor, introduce tu correo para el commit:"
	#read -p "Correo: " correo

	# Configurar la identidad en Git para este repositorio
	#git config user.name "$nombre"
	#git config user.email "$correo"
	#git config --global credential.helper store
	#echo "https://$token@github.com" > ~/.git-credentials
	# Actualizamos la URL remota para incluir el token
	git remote set-url origin git@github.com:apolo176/BashProject.git
    	echo "Debug "
	# Hacer commit y push
	git add .
	read -p "Introduce el mensaje del commit: " commit_msg
	git commit -m "$commit_msg"
    	echo "Intentando subir tus cambios..."
	# Para configurar la rama upstream y hacer el push en la rama main
	git push -u origin main
	if [ $? -eq 0 ]; then
		echo "El repositorio se ha actualizado correctamente."
	else
		echo "Error al actualizar el repositorio. Revisa tu conexión y credenciales."
	fi
}
function salirMenu()
{
	echo "Fin del Programa"
}
### Main ###
opcionmenuppal=0
while test $opcionmenuppal -ne 26
do
    	#Muestra el menu
	echo -e "0 Empaqueta y comprime los ficheros clave del proyecto\n"
	echo -e "1 Eliminar la instalación de mysql\n"
	echo -e "2 Crea la nueva ubicación \n"
	echo -e "3 Copiar ficheros en la nueva ubicación\n"
	echo -e "4 Instalar MySQL\n"
	echo -e "5 Crear usuario en la base de datos\n"
	echo -e "6 Crear base de datos\n"
	echo -e "7 Ejecutar entorno virtual\n"
	echo -e "8 Instalar librerías entorno virtual\n"
	echo -e "9 Ejecutar el servicio\n"
	echo -e "10 Instalar NGINX\n"
	echo -e "11 Arrancar servicio web\n"
	echo -e "12 Testear puertos NGINX\n"
	echo -e "13 Abrir en navegador\n"
	echo -e "14 Personalizar index\n"
	echo -e "15 Instalar Gunicorn\n"
	echo -e "16 Configurar Gunicorn\n"
	echo -e "17 Establecer propiedad y permisos\n"
	echo -e "18 Crear servicio systemd para formulario citas\n"
	echo -e "19 Configurar NGINX\n"
	echo -e "20 Cargar nuevos cambios de la configuración de NGINX\n"
	echo -e "21 Arrancar NGINX\n"
	echo -e "22 Testear virtual host\n"
	echo -e "23 Ver errores de NGINX\n"
	echo -e "24 Copiar servidor remoto\n"
	echo -e "25 Controlar intentos de conexión de SSH\n"
	echo -e "26 salir del Menu \n"
	echo -e "27 Descargar el proyecto de github\n"
	echo -e "28 Actualizar el proyecto en github\n"
    	read -p "Elige una opcion:" opcionmenuppal
    	case $opcionmenuppal in
		0) empaquetaycomprimeFicherosProyecto;;
		1) eliminarMySQL;;
		2) crearNuevaUbicacion;;
		3) copiarFicherosProyectoNuevaUbicacion;;
		4) instalarMySQL;;
		5) crearusuariobasesdedatos;;
		6) crearbasededatos;;
		7) ejecutarEntornoVirtual;;
		8) instalarLibreriasEntornoVirtual;;
		9) probandotodoconservidordedesarrollodeflask;;
		10) instalarNGINX;;
		11) arrancarNGINX;;
		12) testearPuertosNGINX;;
		13) visualizarIndex;;
		14) personalizarIndex;;
		15) instalarGunicorn;;
		16) configurarGunicorn;;
		17) pasarPropiedadyPermisos;;
		18) crearServicioSystemdFormularioCitas;;
		19) configurarNginxProxyInverso;;
		20) cargarFicherosConfiguracionNginx;;
		21) rearrancarNginx;;
		22) testearVirtualHost;;
		23) verNginxLogs;;
		24) copiarServidorRemoto;;
		25) controlarIntentosConexionSSH;;
		26) salirMenu;;
		27) clonarProyectoGitHub ;;
		28) actualizarProyectoGitHub ;;
		*) ;;
    	esac
done
exit 0
