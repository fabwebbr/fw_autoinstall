#!/bin/bash
#
# Objetivo do script: instalar Nginx, PHP 7.4, MySQL e criar vHost de maneira automática.
# Feito para debian/ubuntu
#
# Desenvolvido por Felipe Barreto
###############################################################################################

# Qual timezone usar?
echo "Qual timezone você deseja definir? (Padrão: America/Sao_Paulo)"
read -p "Informe o timezone: " timezone
echo "---"

# Versão do php (Ex: 7.3, 7.4, 8.0, 8.1)
echo "Qual versão do PHP deseja instalar? Disponíveis: 7.2, 7.3, 7.4, 8.0, 8.1, 8.2 e 8.3"
read -p "Informe a versão do PHP: " PHP
echo "---"

# Versão do php (Ex: 7.3, 7.4, 8.0, 8.1)
read -p "Deseja instalar o MySQL? Informe S ou N " MYSQL
echo "---"

# Configurar vhost
echo "Configurar um vHost agora? "
read -p "Informe com S ou N: " VH
echo "---"

if [[ $VH == "S" ]]; then
 read -p "Qual vai ser o domínio do site? (Sem www ou https://): " DOMINIO
 echo "---"
 read -p "Qual o nome do BD? (Ex: nomedosite): " PREFIXOBD
 echo "---"
fi

##############################################################################################
##############################################################################################
##############################################################################################
# Debug? (# = não)
# set -x
# Gerador de numero aleatório
int=$(shuf -i 10-100 -n 1)
# Gerador de senha aleatória para o admin do BD
password_db=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c34)
password_pma=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c30)

#Obter IP do Servidor
IP=`curl http://ifconfig.me`

clear
echo "Iniciando o processo..."

# Define o timezone do servidor
timedatectl set-timezone $timezone > /dev/null 2>&1
# aplica atualizações
echo "Aplicando as atualizações do Sistema Operacional..."
apt-get --yes update > /dev/null 2>&1

# Instalar o Nginx
 echo "NGINX: Iniciando instalação"
 apt-get --yes install nginx > /dev/null 2>&1
 ufw allow "Nginx Full" > /dev/null 2>&1
 rm -rf /var/www/html/index.html
 wget https://github.com/fabwebbr/fw_autoinstall/raw/main/arquivos/index.html -O /var/www/html/index.html
 wget https://github.com/fabwebbr/fw_autoinstall/raw/main/arquivos/logo.png -O /var/www/html/logo.png
 wget https://github.com/fabwebbr/fw_autoinstall/raw/main/arquivos/info.php -O /var/www/html/info.php

# Instalando certbot para nginx
 echo "NGINX: Instalando certbot para Nginx..."
 apt-get --yes install python3-certbot-nginx > /dev/null 2>&1

# Habilita o ppa:ondrej/php
echo "Habilita o ppa:ondrej/php..."
sudo add-apt-repository --yes ppa:ondrej/php

# Instalando PHP do PHPMYADMIN
PHPPMA="7.4"
apt install php${PHPPMA} -y > /dev/null 2>&1
apt --yes install php${PHPPMA}-cli php${PHPPMA}-fpm php${PHPPMA}-mysql php${PHPPMA}-zip php${PHPPMA}-gd php${PHPPMA}-mbstring php${PHPPMA}-curl php${PHPPMA}-xml php${PHPPMA}-bcmath php${PHPPMA}-imagick php${PHPPMA}-intl php${PHPPMA}-soap > /dev/null 2>&1
apt purge apache* --yes > /dev/null 2>&1
apt install -y phpmyadmin

wget https://github.com/fabwebbr/fw_autoinstall/raw/main/modelo-vhost-nginx-phpmyadmin.txt -O /etc/nginx/sites-available/phpmyadmin
/usr/bin/ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin
/usr/bin/systemctl restart nginx > /dev/null 2>&1

# Instalando php
echo "PHP: Iniciando instalação do php ${PHP}..."
apt install php${PHP} -y > /dev/null 2>&1
apt --yes install php${PHP}-cli php${PHP}-fpm php${PHP}-mysql php${PHP}-zip php${PHP}-gd php${PHP}-mbstring php${PHP}-curl php${PHP}-xml php${PHP}-bcmath php${PHP}-imagick php${PHP}-intl php${PHP}-soap > /dev/null 2>&1
apt purge apache* --yes > /dev/null 2>&1
echo "PHP: php${PHP}-fpm foi instalado e está pronto para uso com Nginx"

# Instalando Mysql e configurando acesso
if [[ $MYSQL == "S" ]]; then
 echo "MYSQL: Instalando MySQL..."
 apt-get --yes install mysql-server > /dev/null 2>&1
 /usr/bin/mysql -e "CREATE DATABASE $PREFIXOBD";
 /usr/bin/mysql -e "CREATE USER $PREFIXOBD@localhost IDENTIFIED BY \"$password_db\""
 /usr/bin/mysql -e "GRANT ALL PRIVILEGES ON $PREFIXOBD.* TO $PREFIXOBD@localhost"
 /usr/bin/mysql -e "FLUSH PRIVILEGES"
 #PHPMyAdmin
 /usr/bin/mysql -e "CREATE USER pma_admin@localhost IDENTIFIED BY \"$password_pma\""
 /usr/bin/mysql -e "GRANT ALL PRIVILEGES ON *.* TO pma_admin@localhost WITH GRANT OPTIONS"
 /usr/bin/mysql -e "FLUSH PRIVILEGES"
 echo "Banco de dados criado: "
 echo "Nome BD: $PREFIXOBD" >> /root/acessos-mysql.txt
 echo "Nome Usuário: $PREFIXOBD" >> /root/acessos-mysql.txt
 echo "Senha BD: $password_db" >> /root/acessos-mysql.txt
 echo "-------------------------------"
 echo "Acesso PHPMYADMIN: "
 echo "URL: http://$IP:9000 " >> /root/acessos-mysql.txt
 echo "Login: pma_admin" >> /root/acessos-mysql.txt
 echo "Senha: $password_pma" >> /root/acessos-mysql.txt
fi

if [[ $VH == "S" ]]; then
 wget https://github.com/fabwebbr/fw_autoinstall/raw/main/modelo-vhost-nginx.txt -O /tmp/modelo-vhost.txt
 /usr/bin/cp /tmp/modelo-vhost.txt /etc/nginx/sites-available/$DOMINIO.conf
 /usr/bin/sed -i "s/NOMEDOMINIO/$DOMINIO/g" /etc/nginx/sites-available/$DOMINIO.conf
 /usr/bin/sed -i "s/VPHP/$PHP/g" /etc/nginx/sites-available/$DOMINIO.conf
 /usr/bin/ln -s /etc/nginx/sites-available/$DOMINIO.conf /etc/nginx/sites-enabled/$DOMINIO.conf
fi

clear
echo "-----------------------------------------------------------------------------------------------------------------"
echo "| A instalação do apache, php e mysql foram concluídas. "
echo "| Detalhes: "
echo "| "
if [[ $VH == "S" ]]; then
echo "| Sobre o Site: "
echo "| Pasta do site criado: /var/www/{$DOMINIO}"
echo "| Arquivo vHost: /etc/apache/sites-available/$DOMINIO"
echo "| "
fi
if [[ $MYSQL == "S" ]]; then
echo "| Sobre o MySQL: "
echo "| Nome BD: $PREFIXOBD"
echo "| Nome Usuário: $PREFIXOBD"
echo "| Senha BD: $password_db"
echo "| "
fi
echo "| Sobre o PHPMYADMIN: "
echo "| URL: http://$IP:9000 "
echo "| Login: pma_admin"
echo "| Senha: $password_pma"
echo "| "
echo "| "
echo "| Boa sorte :)"
echo "-----------------------------------------------------------------------------------------------------------------"
exit;