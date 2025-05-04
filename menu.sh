#!/usr/bin/bash
#Prueba
function empaquetaycomprimeFicherosProyecto()
{
	# Navega al directorio del proyecto y crea un archivo tar.gz con los ficheros esenciales
	cd /home/$USER/formulariocitas
	tar cvzf  /home/$USER/formulariocitas.tar.gz app.py script.sql  .env requirements.txt templates/*
}

function eliminarMySQL()
{
	# Detiene el servicio MySQL
	sudo systemctl stop mysql.service
	# Elimina completamente MySQL y sus configuraciones
	sudo apt purge mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
	# Elimina dependencias no necesarias
	sudo apt autoremove
	# Limpia la caché de paquetes
	sudo apt autoclean
	# Elimina los datos, configuraciones y logs de MySQL para una limpieza completa
	sudo rm -rf /var/lib/mysql
	sudo rm -rf /etc/mysql/
	sudo rm -rf /var/log/mysql
}

function crearNuevaUbicacion()
{
	# Crea una nueva ubicación para el proyecto, borrando la existente si ya está
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
	# Extrae los ficheros del proyecto en la nueva ubicación
	tar -xf /home/$USER/formulariocitas.tar.gz -C /var/www/formulariocitas
}

function instalarMySQL()
{
	# Verifica si MySQL está instalado y lo inicia si no está corriendo; si no está instalado, lo instala
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
	# Crea un script SQL para crear el usuario 'lsi' con permisos amplios y lo ejecuta en MySQL
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
	# Ejecuta un script SQL con la cuenta del usuario 'lsi' para crear y configurar la base de datos
	mysql -u lsi -p < /home/$USER/formulariocitas/script.sql 
	return
}

function ejecutarEntornoVirtual()
{
	# Instala dependencias necesarias y crea un entorno virtual Python en el proyecto
	sudo apt update
	sudo apt -y upgrade
	sudo apt install -y python3-venv python3-dev build-essential libssl-dev libffi-dev python3-setuptools python3-pip
	cd /var/www/formulariocitas
	python3 -m venv venv
	source venv/bin/activate
}

function instalarLibreriasEntornoVirtual()
{
	# Activa el entorno virtual e instala las librerías requeridas del proyecto
	cd /var/www/formulariocitas
	source venv/bin/activate
	python -m pip install --upgrade pip
	pip install -r requirements.txt
	# kepa activa y desactiva todo el rato 
}

function probandotodoconservidordedesarrollodeflask()
{
	# Ejecuta la aplicación Flask en modo desarrollo
	python3 /home/$USER/formulariocitas/app.py
}

function instalarNGINX()
{
	# Verifica si NGINX está instalado, y si no lo está, lo instala
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
	# Verifica si el servicio NGINX está en ejecución, y si no, lo inicia
	if  systemctl status nginx.service > /dev/null 2>&1;
	then
		echo "El servicio está en marcha"
		return
	fi
	sudo systemctl start nginx.service
}

function testearPuertosNGINX()
{ 
	# Verifica si 'net-tools' está instalado y lo instala si no está presente
	# Luego, muestra el estado de los puertos abiertos por NGINX
	if !dpkg -s | grep net-tools/etc/nginx/conf.d/;then
		sudo apt install net-tools
	fi
	sudo netstat -anp | grep nginx
}

function visualizarIndex()
{ 
	# Abre el navegador Firefox en la URL local del servidor NGINX (localhost)
	firefox http://localhost
}

function personalizarIndex()
{ 
	# Personaliza el archivo index.html de NGINX con contenido HTML básico
	# Este contenido incluye una tabla con el nombre del grupo y algunos detalles
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
	# Activa el entorno virtual y instala Gunicorn para servir la aplicación Flask
	cd /var/www/formulariocitas
	source venv/bin/activate
	pip install gunicorn
	# Comprobación de si Gunicorn está instalado usando pip
}

function configurarGunicorn()
{ 
	# Configura Gunicorn creando el archivo wsgi.py para lanzar la aplicación Flask
	# Luego, ejecuta Gunicorn en el puerto 5000 y abre Firefox en localhost
	cd /var/www/formulariocitas
	source venv/bin/activate
	GunicornFile="wsgi.py"
	touch "$GunicornFile"
	echo "from app import app">wsgi.py
	echo "if __name__=='__main__':" >> wsgi.py
	echo "	app.run()" >> wsgi.py
	gunicorn --bind localhost:5000 wsgi:app &
	firefox localhost:5000
}

function pasarPropiedadyPermisos()
{ 
	# Cambia la propiedad y los permisos de los archivos del proyecto a 'www-data'
	# Esto es necesario para que el servidor web NGINX pueda acceder a los archivos
	sudo chown -R www-data:www-data /var/www/formulariocitas
	echo "La propiedad ha sido transferida al <usuario:grupo>: <www-data:www-data>."
}

function crearServicioSystemdFormularioCitas()
{ 
	# Crea un servicio systemd para gestionar la aplicación Flask con Gunicorn
	# Configura el servicio para que se ejecute como 'www-data' y se reinicie automáticamente
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
	# Recarga el daemon de systemd, habilita el servicio para que se inicie automáticamente y lo arranca
	sudo systemctl daemon-reload
	echo "Servicio creado en /etc/systemd/system/formulariocitas.service "
	sudo systemctl enable formulariocitas
	sudo systemctl start formulariocitas
	echo "Verificando estado del servicio..."
	sleep 1  # Pequeña pausa para dar tiempo al servicio a arrancar

	# Verifica si el servicio está activo y muestra el resultado
	if systemctl is-active --quiet formulariocitas; then
        	echo "✅ El servicio 'formulariocitas' se ha creado y está activo."
	else
		echo "❌ El servicio 'formulariocitas' no está activo. Revisa los logs con:"
		echo "   sudo journalctl -u formulariocitas -e"
	fi
}

function configurarNginxProxyInverso()
{ 
	# Configura NGINX como proxy inverso para redirigir tráfico desde el puerto 3128 hacia el puerto 5000 (donde Gunicorn sirve Flask)
	local conf_path="/etc/nginx/conf.d/formulariocitas.conf"
	if [ -f "$conf_path" ]; then
		echo "⚠️  El archivo $conf_path ya existe. No se ha hecho ninguna modificación."
	else
		# Si no existe el archivo de configuración, lo crea con los parámetros adecuados
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
	# Verifica si la configuración de NGINX es válida y recarga el servicio si es necesario
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
	# Recarga la configuración de NGINX para aplicar los cambios realizados en los archivos de configuración
	sudo systemctl reload nginx
	echo "⚙️ Nginx recargado correctamente con la nueva configuración."
}

function rearrancarNginx()
{ 
	# Reinicia el servicio de NGINX para aplicar cambios en la configuración
	sudo systemctl restart nginx
	echo "🚀 Nginx reiniciado correctamente."
}

function testearVirtualHost()
{ 
	# Realiza una prueba para verificar que el servicio esté funcionando correctamente
	# Redirige al navegador para comprobar que se pueda acceder a la aplicación
	echo "🔎 Vamos a testear el servicio"
	echo "⚠️ En unos segundos se te redirigirá al navegador"
	sleep 3
 	firefox http://127.0.0.1:8080
}
function verNginxLogs()
{ 
	# Muestra las últimas 10 líneas del archivo de errores de NGINX
	tail -10 /var/log/nginx/error.log
}

function copiarServidorRemoto()
{ 
	# Instala y habilita el servicio SSH para permitir conexiones remotas
	sudo apt install openssh-service
	sudo systemctl enable ssh
	sudo systemctl start ssh

	# Solicita la IP del servidor remoto
	echo "Introduce la IP del servidor remoto"
	read ip

	# Copia los archivos necesarios al servidor remoto usando scp
	scp menu.sh $USER@$ip:/home/$USER/formulariocitas
	scp formulariocitas.tar.gz $USER@$ip:/home/$USER/formulariocitas

	# Conecta al servidor remoto por SSH y ejecuta el script
	ssh $USER@$ip
	bash -x menu.sh
}

function controlarIntentosConexionSSH()
{
	# Analiza los logs de autenticación para detectar intentos de conexión SSH exitosos o fallidos
	echo "Analizando logs de intentos de conexión SSH..."

	# Lista los archivos auth.log, incluyendo comprimidos
	LOGS=$(ls /var/log/auth.log* 2>/dev/null)

	for LOG in $LOGS; do
		if [[ $LOG == *.gz ]]; then
			zcat "$LOG"
		else
			cat "$LOG"
		fi
	done | grep "sshd" | grep -E "Failed password|Accepted password" | while read -r LINE; do
		# Extrae fecha, estado (fail/accept) y nombre de usuario del intento de conexión
		DATE=$(echo "$LINE" | awk '{print $1, $2, $3}')
		STATUS=$(echo "$LINE" | grep -q "Failed password" && echo "fail" || echo "accept")
		USER=$(echo "$LINE" | awk '{for(i=1;i<=NF;i++) if($i=="for") print $(i+1)}')
		echo "\"Status: [$STATUS] Account name: $USER Date: $DATE\""
	done
}

function clonarProyectoGitHub() {
	# Clona un repositorio privado desde GitHub usando un token de acceso personal (PAT)
	token="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"
	repo_url="https://$token@github.com/apolo176/BashProject.git"

	# Solicita la ruta de destino
	read -p "Introduce el directorio destino (ruta absoluta): " destino

	if [ -d "$destino/.git" ]; then
		# Si ya es un repositorio, hace pull
		echo "El directorio ya contiene un repositorio Git. Ejecutando git pull..."
		cd "$destino"
		git pull origin main
	else
		# Si no lo es, lo clona desde cero
		echo "El directorio no existe o no es un repositorio. Clonando..."
		mkdir -p "$destino"
		git clone "$repo_url" "$destino"
	fi

	# Muestra resultado final
	if [ $? -eq 0 ]; then
		echo "Operación realizada exitosamente en $destino."
	else
		echo "Error al realizar la operación. Revisa la URL, los permisos y la configuración."
	fi
}

function actualizarProyectoGitHub() {
	# Actualiza el repositorio subiendo cambios a GitHub
	token="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"
	echo "Introduce esto cuando pida la contraseña $token"

	proyecto="/home/$USER/formulariocitas"

	# Verifica si es un repositorio Git válido
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
 
	# Configura el origen del repositorio para usar SSH (se espera que tengas una clave configurada)
	git remote set-url origin git@github.com:apolo176/BashProject.git

	echo "Debug"

	# Añade todos los cambios, pide mensaje de commit, y hace push
	git add .
	read -p "Introduce el mensaje del commit: " commit_msg
	git commit -m "$commit_msg"

	echo "Intentando subir tus cambios..."
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


echo "hola kurt"
