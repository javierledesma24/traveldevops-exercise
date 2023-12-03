#!/dev/bash

# Variables
repo="bootcamp-devops-2023"
rama="clase2-linux-bash"
USERID=$(id -u)
WEBHOOK_URL="https://discord.com/api/webhooks/1180284341293695067/b_Ga89_4pgyA1Km6pCdFuXYjSvAhn6ZaP6zPsvTwUNWjQMboM759lOKjntjay2wo61Rk"

# Colores
LRED='\033[1;31m'
LGREEN='\033[1;32m'
NC='\033[0m'
LBLUE='\033[0;34m'
PINK='\033[0;35m'
LYELLOW='\033[1;33m'

# Comprobar Usuario Root
if [ "${USERID}" -ne 0 ]; then
    echo -e "\n${LRED}Ejecutar con usuario ROOT${NC}"
    exit
fi 


# Actualizar repositorios
echo -e "\n${LYELLOW}Actualizando Repositorios...${NC}"
apt-get update > /dev/null
echo -e "\n${LGREEN}El Repositorio se encuentra Actualizado${NC}"

# Instalar curl
if dpkg -s curl > /dev/null 2>&1; then
    echo -e "\n${LBLUE}Curl ya se encuentra Instalado${NC}"
else 
    echo -e "\n${LYELLOW}Instalando Curl...${NC}"
    apt-get install curl -y > /dev/null
    echo -e "\n${LGREEN}Curl Instalado${NC}"
fi


# Instalar git
if dpkg -s git > /dev/null 2>&1; then
    echo -e "\n${LBLUE}GIT ya se encuentra Instalado${NC}"
else 
    echo -e "\n${LYELLOW}Instalando git...${NC}"
    apt-get install git -y > /dev/null
    echo -e "\n${LGREEN}GIT Instalado${NC}"
fi
 
# Instalar maria-db 
if dpkg -s mariadb-server > /dev/null 2>&1; then
    echo -e "\n${LBLUE}Maria-db ya se encuentra Instalado${NC}"
else    
    echo -e "\n${LYELLOW}Instalando maria-db...${NC}"
    apt-get install -y mariadb-server > /dev/null
    echo -e "\n${LGREEN}Maria-db Instalado${NC}"

    #Iniciando la base de datos
    systemctl start mariadb
    systemctl enable mariadb
    echo -e "\n${PINK}Estado de maria-db"
    echo 
    systemctl status mariadb | cat | head -11
    echo -e "\n${NC}"

    
    # Crear DB, usuario y otorgarle permisos
    echo -e "\n${LBLUE}Configurando base de datos...${NC}"
        
    mysql -e "CREATE DATABASE devopstravel;
    CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
    GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
    FLUSH PRIVILEGES;"
        
if [ $? -eq 0 ];then
        echo -e "\n${LBLUE}Base de Datos Configurada${NC}"
    else 
        echo -e "\n${LRED}Error en Configuracion de Base Datos${NC}"
    fi
fi 

# Deployar y Configurar Web

if dpkg -s apache2 > /dev/null 2>&1; then
    echo -e "\n${LBLUE}Apache2 ya se encuentra instalado${NC}"    
else    
    echo -e "\n${LYELLOW}Se esta instalando apache2...${NC}"
    apt-get install -y apache2 > /dev/null
    apt-get install -y php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl > /dev/null 
    echo -e "\n${LGREEN}Apache2 Instalado${NC}"
    echo        
fi

# Iniciar Apache2
systemctl start apache2
systemctl enable apache2
echo -e "\n${LGREEN}Estado de Apache2"
echo -e "\n${PINK}"
echo 
systemctl status apache2 | cat
echo -e "\n${NC}"

# Comprobar si existe index.html
if [ -e /var/www/html/index.html ]; then
    echo "Existe el archivo index.html"
    mv /var/www/html/index.html /var/www/html/index.html.bkp
fi

# Comprobar si la carpeta del repo existe
if [ -d "$repo" ]; then
    echo -e "\n${LBLUE}La carpeta $repo existe${NC}"
    echo -e "\n${LYELLOW}Actualizando WEB...${NC}"
    cd $repo
    git pull
    cd ..
    cp -rf $repo/app-295devops-travel/* /var/www/html
    sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
    echo -e "\n${LGREEN}WEB Actualizada${NC}"
    
else
    echo -e "\n${LYELLOW}Instalando WEB...${NC}"
    sleep 1
    git clone -b $rama https://github.com/roxsross/$repo.git 
    cp -rf $repo/app-295devops-travel/* /var/www/html
    sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
    echo -e "\n${LGREEN}WEB Instalada${NC}"
fi



# Agregar datos a la DB
resultado=$(mysql -e "USE devopstravel;SELECT * FROM booking" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "\n${LGREEN}La base de Datos ya esta Completa${NC}"
else
    echo -e "\n${LYELLOW}Completando Base de Datos...${NC}"
    mysql < $repo/app-295devops-travel/database/devopstravel.sql
    echo -e "\n${LGREEN}Base de Datos Completa${NC}"
fi


# Reload Apache2
systemctl reload apache2

# Obtiene el nombre del repositorio

cd $repo

REPO_NAME=$(basename $(git rev-parse --show-toplevel))

# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="localhost"

# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1)

cd ..

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    
    cd $repo
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
    cd ..

else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Obtén información del repositorio


# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" -d '{"content": "'"${MESSAGE}"'"}' "$WEBHOOK_URL"
