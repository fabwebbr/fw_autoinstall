#!/bin/bash
#
# Objetivo do script: instalar Apache2, PHP 7.4, MySQL e WordPress de maneira automática.
# Feito para debian/ubuntu
#
# Desenvolvido por Felipe Barreto
###############################################################################################

# Qual timezone usar?
timezone="America/Sao_Paulo"

# Versão do php (Ex: 7.3, 7.4, 8.0, 8.1)
PHP="7.4"

##############################################################################################
##############################################################################################
##############################################################################################
# Debug? (# = não)
# set -x
# Gerador de numero aleatório
int=$(shuf -i 10-100 -n 1)
# Gerador de nome para o BD
nome_db=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c12)
# Gerador de usuário para o BD
user_db=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c12)
# Gerador de senha aleatória para o BD
password_db=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c34)
# Gerador de senha para o wp-admin
adminpass_wp=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c18)

# Start
clear

echo "Iniciando o processo...."
timedatectl set-timezone $timezone > /dev/null 2>&1
apt-get --yes --quiet update > /dev/null 2>&1
if [ ? -eq 0 ]; then
 echo "As atualizações foram aplicadas"
fi

# Instalando Apache e habilitando módulos
if [ -d "/etc/apache2" ]; then
 echo "APACHE: Já existe uma instalação. Pulando esta etapa..."; 
 sleep 2;
else
 echo "APACHE: Iniciando instalação"
 apt-get --yes --quiet install apache2 libapache2-mod-security2 > /dev/null 2>&1

 echo "APACHE: Habilitando módulos..."
 a2enmod rewrite > /dev/null 2>&1 && a2enmod deflate > /dev/null 2>&1 
 a2enmod expires > /dev/null 2>&1 && a2enmod http2 > /dev/null 2>&1 
 a2enmod proxy > /dev/null 2>&1 && a2enmod proxy_fcgi > /dev/null 2>&1 
 a2enmod ssl > /dev/null 2>&1 && a2enmod reqtimeout > /dev/null 2>&1
 a2dissite 000-default > /dev/null 2>&1 && a2enmod headers > /dev/null 2>&1
 rm -rf /etc/apache2/sites-available/*.conf
 rm -rf /var/www/html
 systemctl restart apache2 > /dev/null 2>&1
 ufw allow "Apache Full" > /dev/null 2>&1
 
 echo "APACHE + SSL: Instalando certbot para apache..."
 apt-get --yes --quiet install python3-certbot-apache > /dev/null 2>&1
fi

# Instalando php 7.4
sudo add-apt-repository ppa:ondrej/php --quiet > /dev/null 2>&1
sudo apt update --quiet > /dev/null 2>&1
if [ -d "/etc/php/${PHP}" ]; then
 echo "PHP: A instalação do php ${PHP} já existe. Pulando esta etapa..."
 apt --quiet --yes install php${PHP}-cli php${PHP}-fpm php${PHP}-mysql php${PHP}-zip php${PHP}-gd php${PHP}-mbstring php${PHP}-curl php${PHP}-xml php${PHP}-bcmath php${PHP}-imagick php${PHP}-intl php${PHP}-soap > /dev/null 2>&1
else
 echo "PHP: Iniciando instalação do php ${PHP}..."
 apt install php${PHP} -y --quiet > /dev/null 2>&1
 apt --quiet --yes install php${PHP}-cli php${PHP}-fpm php${PHP}-mysql php${PHP}-zip php${PHP}-gd php${PHP}-mbstring php${PHP}-curl php${PHP}-xml php${PHP}-bcmath php${PHP}-imagick php${PHP}-intl php${PHP}-soap > /dev/null 2>&1
 a2enconf php${PHP}-fpm > /dev/null 2>&1
 echo "PHP: php${PHP}-fpm foi instalado e está pronto para uso com Apache2"
fi

# Instalando Mysql e configurando acesso
echo "MYSQL: Instalando MySQL..."
apt-get --yes --quiet install mysql-server > /dev/null 2>&1

mysql -e "create user $user_db@localhost IDENTIFIED WITH mysql_native_password BY '$password_db'" > /dev/null 2>&1
mysql -e "GRANT ALL ON *.* TO $user_db@localhost" > /dev/null 2>&1
mysql -e "CREATE DATABASE $nome_db"
mysql -e "FLUSH PRIVILEGES" > /dev/null 2>&1

cat > /root/.my.cnf << EOF
[client]
user=$user_db
password=$password_db
EOF
echo "MYSQL: Usuário do banco de dados configurado"

 wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp > /dev/null 2>&1
 chmod +x /usr/local/bin/wp > /dev/null 2>&1
fi
systemctl restart apache2 > /dev/null 2>&1

clear
echo "-----------------------------------------------------------------------------------------------------------------"
echo "| A instalação do apache, php, mysql e wp-cli foram concluídas. "
echo "| Detalhes: "
echo "| "
echo "| Pasta dos sites: /var/www/"
echo "| Admin senha: $adminpass_wp"
echo "| Nome do BD: $nome_db"
echo "| "
echo "| Os dados de acesso ao banco de dados estão armazenados em /root/.my.cnf"
echo "| "
echo "| Boa sorte :)"
echo "-----------------------------------------------------------------------------------------------------------------"
exit;