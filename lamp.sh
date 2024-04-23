#!/bin/bash
#
# Objetivo do script: instalar Apache2, PHP 7.4, MySQL e criar vHost de maneira automática.
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
 read -p "Qual vai ser o domínio do site? (Sem www ou https://) " DOMINIO
 echo "---"
 read -p "Qual o nome do BD? (Ex: nomedosite)" PREFIXOBD
 echo "---"
fi

exit;

##############################################################################################
##############################################################################################
##############################################################################################
# Debug? (# = não)
# set -x
# Gerador de numero aleatório
int=$(shuf -i 10-100 -n 1)
# Gerador de senha aleatória para o BD
password_db=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c34)

# Start
clear

echo "Iniciando o processo...."
timedatectl set-timezone $timezone > /dev/null 2>&1
apt-get --yes update > /dev/null 2>&1
if [ ? -eq 0 ]; then
 echo "As atualizações foram aplicadas"
fi

# Instalando Apache e habilitando módulos
if [ -d "/etc/apache2" ]; then
 echo "APACHE: Já existe uma instalação. Pulando esta etapa..."; 
 sleep 2;
else
 echo "APACHE: Iniciando instalação"
 apt-get --yes install apache2 libapache2-mod-security2 > /dev/null 2>&1

 echo "APACHE: Habilitando módulos..."
 a2enmod rewrite > /dev/null 2>&1 && a2enmod deflate > /dev/null 2>&1 
 a2enmod expires > /dev/null 2>&1 && a2enmod http2 > /dev/null 2>&1 
 a2enmod proxy > /dev/null 2>&1 && a2enmod proxy_fcgi > /dev/null 2>&1 
 a2enmod ssl > /dev/null 2>&1 && a2enmod reqtimeout > /dev/null 2>&1
 a2enmod headers > /dev/null 2>&1
 systemctl restart apache2 > /dev/null 2>&1
 ufw allow "Apache Full" > /dev/null 2>&1
 
 echo "APACHE + SSL: Instalando certbot para apache..."
 apt-get --yes install python3-certbot-apache > /dev/null 2>&1
fi

# Instalando php 7.4
sudo add-apt-repository ppa:ondrej/php --quiet > /dev/null 2>&1
sudo apt update > /dev/null 2>&1
if [ -d "/etc/php/${PHP}" ]; then
 echo "PHP: A instalação do php ${PHP} já existe. Pulando esta etapa..."
 apt --quiet --yes install php${PHP}-cli php${PHP}-fpm php${PHP}-mysql php${PHP}-zip php${PHP}-gd php${PHP}-mbstring php${PHP}-curl php${PHP}-xml php${PHP}-bcmath php${PHP}-imagick php${PHP}-intl php${PHP}-soap > /dev/null 2>&1
else
 echo "PHP: Iniciando instalação do php ${PHP}..."
 apt install php${PHP} -y > /dev/null 2>&1
 apt --quiet --yes install php${PHP}-cli php${PHP}-fpm php${PHP}-mysql php${PHP}-zip php${PHP}-gd php${PHP}-mbstring php${PHP}-curl php${PHP}-xml php${PHP}-bcmath php${PHP}-imagick php${PHP}-intl php${PHP}-soap > /dev/null 2>&1
 a2enconf php${PHP}-fpm > /dev/null 2>&1
 echo "PHP: php${PHP}-fpm foi instalado e está pronto para uso com Apache2"
fi

# Instalando Mysql e configurando acesso
if [[ $MYSQL == "S" ]]; then
 echo "MYSQL: Instalando MySQL..."
 apt-get --yes --quiet install mysql-server > /dev/null 2>&1
 /usr/bin/mysql -e "CREATE DATABASE $PREFIXOBD";
 /usr/bin/mysql -e "CREATE USER $PREFIXOBD@localhost IDENTIFIED BY \"$password_db\""
 /usr/bin/mysql -e "GRANT ALL PRIVILEGES ON $PREFIXOBD.* TO $PREFIXOBD@localhost"
 /usr/bin/mysql -e "FLUSH PRIVILEGES"
 echo "Nome BD: $PREFIXOBD" >> /root/acessos-mysql.txt
 echo "Nome Usuário: $PREFIXOBD" >> /root/acessos-mysql.txt
 echo "Senha BD: $password_db" >> /root/acessos-mysql.txt
fi

if [[ $VH == "S" ]]; then
 wget https://github.com/fabwebbr/fw_autoinstall/raw/main/modelo-vhost-apache-1.txt -O /tmp/modelo-vhost.txt
 cp /tmp/modelo-vhost.txt /etc/apache2/sites-available/$DOMINIO.conf
 /usr/bin/sed -i "s/NOMEDOMINIO/$DOMINIO/g" /etc/apache2/sites-available/$DOMINIO.conf
 /usr/bin/sed -i "s/VPHP/$PHP/g" /etc/apache2/sites-available/$DOMINIO.conf
 /usr/sbin/a2ensite $DOMINIO.conf
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
fi
if [[ $MYSQL == "S" ]]; then
echo "| Sobre o MySQL: "
echo "| Nome BD: $PREFIXOBD"
echo "| Nome Usuário: $PREFIXOBD"
echo "| Senha BD: $password_db"
fi
echo "| "
echo "| Boa sorte :)"
echo "-----------------------------------------------------------------------------------------------------------------"
exit;