#!/usr/bin/bash
#Prueba
function empaquetaycomprimeFicherosProyecto() {
	# Navega al directorio del proyecto y crea un archivo tar.gz con los ficheros esenciales
	echo "🔄 Empaquetando y comprimiendo ficheros del proyecto..."
	cd /home/$USER/formulariocitas > /dev/null 2>&1
	if tar czf /home/$USER/formulariocitas.tar.gz app.py script.sql .env requirements.txt templates/* > /dev/null 2>&1; then
		echo "✅ Archivo formulariocitas.tar.gz creado correctamente."
	else
		echo "❌ Fallo al crear el archivo tar.gz."
	fi
}

function eliminarMySQL()
{
	# Detiene el servicio MySQL
	echo "🔄 Deteniendo servicio MySQL..."
	sudo systemctl stop mysql.service > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ MySQL detenido."
	else
		echo "❌ No se pudo detener MySQL."
	fi
	# Elimina completamente MySQL y sus configuraciones
	echo "🗑️  Purge de paquetes MySQL..."
	sudo apt purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Paquetes MySQL purgados."
	else
		echo "❌ Error al purgar paquetes MySQL."
	fi

	# Elimina dependencias no necesarias
	echo "🧹 Eliminando dependencias y caché..."
	sudo apt autoremove -y > /dev/null 2>&1
	sudo apt autoclean -y > /dev/null 2>&1
	echo "✅ Dependencias innecesarias y caché eliminadas."
	# Elimina los datos, configuraciones y logs de MySQL para una limpieza completa
	echo "🚮 Eliminando datos y configuraciones..."
	sudo rm -rf /var/lib/mysql /etc/mysql /var/log/mysql > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Datos de MySQL eliminados."
	else
		echo "❌ Error al eliminar datos de MySQL."
	fi
}

function crearNuevaUbicacion()
{
	# Crea una nueva ubicación para el proyecto, borrando la existente si ya está
	echo "🔄 Reconfigurando /var/www/formulariocitas..."
	if [ -d /var/www/formulariocitas ]; then
		echo "🗑️  Borrando directorio existente..."
		sudo rm -rf /var/www/formulariocitas > /dev/null 2>&1
		echo "✅ Directorio anterior eliminado."
	fi
	echo "📁 Creando directorio..."
	sudo mkdir -p /var/www/formulariocitas > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Directorio creado."
	else
		echo "❌ Error al crear directorio."
	fi

	echo "🔧 Ajustando permisos..."
	sudo chown -R $USER:$USER /var/www/formulariocitas > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Permisos asignados a $USER."
	else
		echo "❌ No se pudieron cambiar permisos."
	fi

	read -p "Pulsa ENTER para continuar..."
}

function copiarFicherosProyectoNuevaUbicacion()
{
	# Extrae los ficheros del proyecto en la nueva ubicación
	echo "🔄 Extrayendo ficheros en /var/www/formulariocitas..."
	if tar xf /home/$USER/formulariocitas.tar.gz -C /var/www/formulariocitas > /dev/null 2>&1; then
		echo "✅ Ficheros extraídos correctamente."
	else
		echo "❌ Fallo al extraer ficheros."
	fi
}

function instalarMySQL()
{
	# Verifica si MySQL está instalado y lo inicia si no está corriendo; si no está instalado, lo instala
	echo "🔄 Comprobando instalación de MySQL..."
	if dpkg -l | grep -q mysql-server; then
		echo "ℹ️  MySQL ya está instalado."
	else
		echo "⬇️  Instalando MySQL..."
		sudo apt update > /dev/null 2>&1 && \
		sudo apt install -y mysql-server > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "✅ MySQL instalado."
		else
			echo "❌ Fallo al instalar MySQL."
		fi
	fi

	echo "▶️  Iniciando MySQL si no está activo..."
	sudo systemctl start mysql.service > /dev/null 2>&1
	if systemctl is-active --quiet mysql.service; then
		echo "✅ Servicio MySQL en marcha."
	else
		echo "❌ No se pudo iniciar MySQL."
	fi
}

function crearusuariobasesdedatos()
{
	# Crea un script SQL para crear el usuario 'lsi' con permisos amplios y lo ejecuta en MySQL
	local sqlScript="/home/$USER/formulariocitas/crear_usuario.sql"

	echo "🔄 Generando script SQL de usuario..."
	touch "$sqlScript" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Archivo $sqlScript creado."
	else
		echo "❌ No se pudo crear $sqlScript."
		return
	fi

	echo "🔄 Escribiendo comandos en el script..."
	cat <<EOF > "$sqlScript"
		CREATE USER 'lsi'@'localhost' IDENTIFIED BY 'lsi';
		GRANT CREATE, ALTER, DROP, INSERT, UPDATE, INDEX, DELETE, SELECT,
		    REFERENCES, RELOAD ON *.* TO 'lsi'@'localhost' WITH GRANT OPTION;
		FLUSH PRIVILEGES;
	EOF
	if [ $? -eq 0 ]; then
		echo "✅ Script SQL rellenado."
	else
		echo "❌ Error al escribir en $sqlScript."
		return
	fi

	echo "▶️  Ejecutando script en MySQL..."
	sudo mysql < "$sqlScript" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Usuario 'lsi' creado y permisos asignados."
	else
		echo "❌ Fallo al ejecutar el script SQL."
	fi
}

function crearbasededatos()
{
	# Ejecuta un script SQL con la cuenta del usuario 'lsi' para crear y configurar la base de datos
	local script="/home/$USER/formulariocitas/script.sql"
	
	echo "🔄 Ejecutando script de creación de base de datos..."
	mysql -u lsi -p < "$script" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Base de datos configurada correctamente."
	else
		echo "❌ Error al ejecutar $script."
	fi
}

function ejecutarEntornoVirtual()
{
	# Instala dependencias necesarias y crea un entorno virtual Python en el proyecto
	echo "🔄 Preparando entorno virtual..."
	sudo apt update > /dev/null 2>&1
	sudo apt -y upgrade > /dev/null 2>&1
	sudo apt install -y python3-venv python3-dev build-essential libssl-dev libffi-dev python3-setuptools python3-pip > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Dependencias instaladas."
	else
		echo "❌ Error al instalar dependencias."
		return
	fi

	cd /var/www/formulariocitas > /dev/null 2>&1
	echo "🔄 Creando entorno virtual venv..."
	python3 -m venv venv > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Entorno virtual creado."
	else
		echo "❌ Error al crear entorno virtual."
		return
	fi

	echo "▶️  Activando entorno virtual..."
	source venv/bin/activate
	if [ $? -eq 0 ]; then
		echo "✅ Entorno virtual activado."
	else
		echo "❌ Error al activar entorno virtual."
	fi
}

function instalarLibreriasEntornoVirtual()
{
	# Activa el entorno virtual e instala las librerías requeridas del proyecto
	echo "🔄 Instalando librerías en el entorno virtual..."
	cd /var/www/formulariocitas > /dev/null 2>&1
	source venv/bin/activate > /dev/null 2>&1
	python -m pip install --upgrade pip > /dev/null 2>&1
	pip install -r requirements.txt > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Librerías instaladas correctamente."
	else
		echo "❌ Error al instalar librerías."
	fi
}

function probandotodoconservidordedesarrollodeflask()
{
	# Ejecuta la aplicación Flask en modo desarrollo
	echo "🔄 Iniciando servidor de desarrollo Flask..."
	python3 /home/$USER/formulariocitas/app.py > /dev/null 2>&1 &
	PID=$!
	sleep 1
	if ps -p $PID > /dev/null 2>&1; then
		echo "✅ Servidor Flask corriendo (PID $PID)."
		echo "   CTRL+C para detener."
		wait $PID
	else
		echo "❌ No se pudo iniciar el servidor Flask."
	fi
}

function instalarNGINX()
{
	# Verifica si NGINX está instalado, y si no lo está, lo instala
		echo "🔄 Instalando NGINX..."
	if dpkg -s nginx > /dev/null 2>&1; then
		echo "ℹ️  NGINX ya estaba instalado."
	else
		sudo apt update > /dev/null 2>&1
		sudo apt install -y nginx > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "✅ NGINX instalado correctamente."
		else
			echo "❌ Error al instalar NGINX."
			return
		fi
	fi

}

function arrancarNGINX()
{
	# Verifica si el servicio NGINX está en ejecución, y si no, lo inicia
	echo "🔄 Arrancando NGINX..."
	sudo systemctl start nginx.service > /dev/null 2>&1
	if systemctl is-active --quiet nginx.service; then
		echo "✅ Servicio NGINX en marcha."
	else
		echo "❌ No se pudo iniciar NGINX."
	fi
}

function testearPuertosNGINX()
{ 
	# Verifica si 'net-tools' está instalado y lo instala si no está presente
	# Luego, muestra el estado de los puertos abiertos por NGINX
	echo "🔄 Comprobando net-tools..."
	if ! dpkg -s net-tools > /dev/null 2>&1; then
		sudo apt install -y net-tools > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "✅ net-tools instalado."
		else
			echo "❌ Error al instalar net-tools."
			return
		fi
	else
		echo "ℹ️  net-tools ya instalado."
	fi

	echo "🔄 Listando puertos abiertos por NGINX..."
	sudo netstat -anp 2>/dev/null | grep nginx && echo "✅ Puertos mostrados." || echo "❌ No se encontraron puertos nginx."
}
}

function visualizarIndex()
{ 
	# Abre el navegador Firefox en la URL local del servidor NGINX (localhost)
	echo "🔄 Abriendo index en Firefox..."
	firefox http://localhost > /dev/null 2>&1 &
	if [ $? -eq 0 ]; then
		echo "✅ Firefox abierto en http://localhost"
	else
		echo "❌ No se pudo abrir Firefox."
	fi
}

function personalizarIndex()
{ 
	# Personaliza el archivo index.html de NGINX con contenido HTML básico
	# Este contenido incluye una tabla con el nombre del grupo y algunos detalles
	local file="/var/www/html/index.html"
	echo "🔄 Personalizando index.html..."
	sudo tee "$file" > /dev/null <<EOF
	<!DOCTYPE html>
	<html>
	<head>
	    <title>NOMBRE DEL GRUPO</title>
	</head>
	<body>
	<center><h1>NOMBRE DEL GRUPO</h1></center>
	<table border="5" bordercolor="red" align="center">
	    <tr><th colspan="3">NOMBRE DEL GRUPO</th></tr>
	    <tr><th>Nombre</th><th>Apellidos</th><th>Foto</th></tr>
	    <tr><td>Kepa</td><td>Bengoetxea Kortazar</td><td border="3" height="100" width="100">Photo1</td></tr>
	</table>
	<center>El cabeza de grupo es Kepa Bengoetxea</center>
	</body>
	</html>
	EOF
	if [ $? -eq 0 ]; then
		echo "✅ index.html personalizado."
	else
		echo "❌ Error al personalizar index.html."
	fi
}

function instalarGunicorn()
{ 
	# Activa el entorno virtual y instala Gunicorn para servir la aplicación Flask
	echo "🔄 Instalando Gunicorn..."
	cd /var/www/formulariocitas > /dev/null 2>&1
	source venv/bin/activate > /dev/null 2>&1
	pip install --upgrade pip gunicorn > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Gunicorn instalado en el entorno virtual."
	else
		echo "❌ Error al instalar Gunicorn."
	fi
}

function configurarGunicorn()
{ 
	# Configura Gunicorn creando el archivo wsgi.py para lanzar la aplicación Flask
	# Luego, ejecuta Gunicorn en el puerto 5000 y abre Firefox en localhost
	echo "🔄 Configurando Gunicorn service..."
	cd /var/www/formulariocitas > /dev/null 2>&1
	source venv/bin/activate > /dev/null 2>&1

	local wsgi="wsgi.py"
	touch "$wsgi" > /dev/null 2>&1
	cat <<EOF > "$wsgi"
	from app import app
	if __name__=='__main__':
		app.run()
	EOF
	if [ $? -eq 0 ]; then
		echo "✅ Archivo wsgi.py creado."
	else
		echo "❌ Error al crear wsgi.py."
		return
	fi

	echo "▶️  Iniciando Gunicorn..."
	gunicorn --bind localhost:5000 wsgi:app > /dev/null 2>&1 &
	sleep 1
	pgrep -f "gunicorn: master" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Gunicorn corriendo en localhost:5000."
		read -p "¿Quieres abrir el navegador en http://localhost:5000? [s/N]: " resp
		if [[ "$resp" =~ ^[sS]$ ]]; then
			firefox http://localhost:5000 > /dev/null 2>&1 &
			echo "✅ Firefox abierto en http://localhost:5000"
		else
			echo "ℹ️  No se abrió el navegador."
		fi
	else
		echo "❌ Gunicorn no ha arrancado."
	fi
}

function pasarPropiedadyPermisos()
{ 
	# Cambia la propiedad y los permisos de los archivos del proyecto a 'www-data'
	# Esto es necesario para que el servidor web NGINX pueda acceder a los archivos
	echo "🔄 Ajustando propiedad y permisos a www-data..."
	sudo chown -R www-data:www-data /var/www/formulariocitas > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Propiedad transferida a www-data:www-data."
	else
		echo "❌ Error al cambiar propiedad/permiso."
	fi
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
	echo "🔄 Comprobando puerto 8080..."
	if sudo lsof -i :8080 -t > /dev/null; then
		echo "⚠️  Puerto 8080 ocupado, liberando..."
		sudo kill -9 $(sudo lsof -i :8080 -t) > /dev/null 2>&1
		echo "✅ Puerto 8080 liberado."
	fi

	echo "🔄 Iniciando prueba en http://127.0.0.1:8080..."
	firefox http://127.0.0.1:8080 > /dev/null 2>&1 &
	if [ $? -eq 0 ]; then
		echo "✅ Firefox abierto en http://127.0.0.1:8080"
	else
		echo "❌ No se pudo abrir Firefox."
	fi
}
function verNginxLogs()
{ 
	# Muestra las últimas 10 líneas del archivo de errores de NGINX
		echo "🔄 Mostrando últimos errores de Nginx..."
	if tail -10 /var/log/nginx/error.log; then
		echo "✅ Logs mostrados."
	else
		echo "❌ No se pudieron mostrar los logs."
	fi
}

function copiarServidorRemoto()
{ 
	# Instala y habilita el servicio SSH para permitir conexiones remotas
	echo "🔄 Instalando SSH si hace falta..."
	sudo apt install -y openssh-server > /dev/null 2>&1
	sudo systemctl enable ssh > /dev/null 2>&1
	sudo systemctl start ssh > /dev/null 2>&1
	echo "✅ SSH listo."

	echo "🔄 Introduce IP del servidor remoto:"
	read ip

	echo "🔄 Copiando ficheros a $ip..."
	scp menu.sh "$USER@$ip:/home/$USER/formulariocitas" > /dev/null 2>&1
	scp formulariocitas.tar.gz "$USER@$ip:/home/$USER/formulariocitas" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "✅ Ficheros copiados."
	else
		echo "❌ Error al copiar ficheros."
		return
	fi

	echo "▶️  Conectando por SSH a $ip..."
	ssh "$USER@$ip"
	bash -x menu.sh
}

function controlarIntentosConexionSSH()
{
	# Analiza los logs de autenticación para detectar intentos de conexión SSH exitosos o fallidos
	echo "🔄 Analizando intentos de conexión SSH..."


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
		echo "🔔 Status: [$STATUS] Account name: $USER Date: $DATE\""
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
