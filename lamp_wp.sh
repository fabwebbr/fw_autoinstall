#!/bin/bash
#
# Objetivo do script: instalar Apache2, PHP 7.4, MySQL e WordPress de maneira automática.
# Feito para debian/ubuntu
#
# Desenvolvido por Felipe Barreto
###############################################################################################

# Qual timezone usar?
timezone="America/Sao_Paulo"


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
if [ -z "$1" ]; then
 echo "Você não informou o domínio. O comando deve ser executado como: ./lamp_fw.sh seu-site.com.br";
 exit;
fi

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
if [ -d "/etc/php/7.4" ]; then
 echo "PHP: A instalação do php 7.4 já existe. Pulando esta etapa..."
 apt --quiet --yes install php7.4-cli php7.4-fpm php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath php7.4-imagick php7.4-intl php7.4-soap > /dev/null 2>&1
else
 echo "PHP: Iniciando instalação do php 7.4..."
 apt install php7.4 -y --quiet > /dev/null 2>&1
 apt --quiet --yes install php7.4-cli php7.4-fpm php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath php7.4-imagick php7.4-intl php7.4-soap > /dev/null 2>&1
 a2enconf php7.4-fpm > /dev/null 2>&1
 echo "PHP: php7.4-fpm foi instalado e está pronto para uso com apache"
fi

# Instalando Mysql e configurando acesso
echo "MYSQL: Instalando MySQL..."
apt-get --yes --quiet install mysql-server > /dev/null 2>&1

mysql -e "create user $user_db@localhost IDENTIFIED WITH mysql_native_password BY '$password_db'" > /dev/null 2>&1
mysql -e "GRANT ALL PRIVILEGES ON *.* TO $user_db@localhost" > /dev/null 2>&1
mysql -e "CREATE DATABASE $nome_db"
mysql -e "FLUSH PRIVILEGES" > /dev/null 2>&1

cat > /root/.my.cnf << EOF
[client]
user=$user_db
password=$password_db
EOF
echo "MYSQL: Bancos de dados e usuário configurados"

# Criando o site e Instalando o wp-cli
if [ -d "/var/www/$1" ]; then
 echo "WORDPRESS: Já existe uma pasta de $1 criada..."
else
touch /etc/apache2/sites-available/$1.conf
cat > /etc/apache2/sites-available/$1.conf << EOF
 <VirtualHost *:80>
    ServerAdmin admin@$1
    DocumentRoot /var/www/$1
    ServerName $1
    ServerAlias www.$1

    ErrorLog ${APACHE_LOG_DIR}/$1-error.log
    CustomLog ${APACHE_LOG_DIR}/$1-access.log combined

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/var/run/php/php7.4-fpm.sock|fcgi://localhost"
    </FilesMatch>

    <Directory /var/www/$1>
        Options -Indexes -FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
        Header set X-Content-Type-Options nosniff
    </Directory>

    <Files ".htaccess">
      Order allow,deny
      Deny from all
    </Files>
  </VirtualHost>
EOF
 a2ensite $1
 wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp > /dev/null 2>&1
 chmod +x /usr/local/bin/wp > /dev/null 2>&1
 chown www-data:www-data /var/www/ > /dev/null 2>&1
 sudo -u www-data mkdir /var/www/$1 > /dev/null 2>&1
 cd /var/www/$1
 sudo -u www-data /usr/local/bin/wp core download > /dev/null 2>&1
 sudo -u www-data /usr/local/bin/wp core config --dbname="$nome_db" --dbuser="$user_db" --dbpass="$password_db" --dbhost="localhost" --dbprefix="wp_" > /dev/null 2>&1
 sudo -u www-data /usr/local/bin/wp core install --url="https://$1" --title="Wordpress de $1" --admin_user="admin_${int}" --admin_password="$adminpass_wp" --admin_email="admin@$1" > /dev/null 2>&1
touch /var/www/credenciais.txt > /dev/null 2>&1
cat > /var/www/credenciais.txt << EOF
 URL: https://$1
 URL Admin: https://$1/wp-admin
 Admin Login: admin_${int}
 Admin Senha: $adminpass_wp

 Os dados do MySQL estão no wp-config.php
EOF
fi
systemctl restart apache2 > /dev/null 2>&1

# Verifica se o domínio já resolve para este IP
hash_validacao=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c40)
sudo -u www-data touch /var/www/$1/validador.php
cat > /var/www/$1/validador.php << EOF
<?php
echo $hash_validacao;
?>
EOF
string_teste=`curl http://$1/validador.php`
if [ $hash_validacao = $string_teste ]; then
 certbot --quiet --apache -d $1 -d www.$1 --agree-tos --email admin@$1 > /dev/null 2>&1
 MSGCERT1 = "| Seu domínio já está apontando para este servidor. Verifique se o SSL foi criado corretamente."
 MSGCERT2 = "| Se não foi criado, execute manualmente: certbot --apache2 -d $1 -d www.$1"
else
 MSGCERT1 = "| O domínio $1 não aponta para o IP `curl ipinfo.io/ip` e por isso não foi instalado o SSL."
 MSGCERT2 = "| Se não foi criado, execute manualmente: certbot --apache2 -d $1 -d www.$1"
fi

clear
echo "-----------------------------------------------------------------------------------------------------------------"
echo "| A instalação do apache, php, mysql e Wordpress foram concluídas. "
echo "| Detalhes: "
echo "| Pasta do site: /var/www/$1/ "
echo "| Endereço do site: https://$1"
echo "| Admin URL: https://$1/wp-admin"
echo "| Admin Login: admin_${int}"
echo "| Admin senha: $adminpass_wp"
echo "| Nome do BD: $nome_db"
echo "| "
echo "| Os dados de acesso ao banco de dados estão armazenados em /root/.my.cnf ou em seu wp-config.php"
echo "| Os dados de acesso ao seu Wordpress ficarão guardados em: /var/www/credenciais.txt"
echo "$MSGCERT1"
echo "$MSGCERT2"
echo "| Comando: certbot --apache2 -d $1 -d www.$1"
echo "| "
echo "| Boa sorte :)"
echo "-----------------------------------------------------------------------------------------------------------------"
exit;