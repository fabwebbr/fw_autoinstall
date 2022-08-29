#!/bin/bash
#
# Objetivo do script: instalar Nginx + Certbot, PHP 7.4, MySQL.
# Feito para debian/ubuntu
#
# Desenvolvido por Felipe Barreto
###############################################################################################

# Qual timezone usar?
timezone="America/Sao_Paulo"

# Qual versão do PHP usar?
VERSAO="7.4"

# Instalar mysql? (0 = não, 1 = sim)
MYSQL="1"

##############################################################################################
##############################################################################################
##############################################################################################
# Debug? (# = não)
# set -x
# Gerador de numero aleatório
int=$(shuf -i 10-100 -n 1)
# Gerador de senha aleatória para o admin do BD
password_db=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c34)

clear

echo "Iniciando o processo...."
# Define o timezone do servidor
timedatectl set-timezone $timezone > /dev/null 2>&1
# aplica atualizações
apt-get --yes --quiet update > /dev/null 2>&1

# Verifica se o apache já não está instalado
if [ -d "/etc/apache2" ]; then
 echo "!!! CUIDADO: Já existe uma instalação do apache. Verifique para evitar conflitos."; 
 exit;
else
# Se não estiver, instala o Nginx
 echo "APACHE: Iniciando instalação"
 apt-get --yes install apache2 libapache2-mod-security2 > /dev/null 2>&1
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
# Instalando certbot para apache
 apt-get --yes install python3-certbot-apache > /dev/null 2>&1
fi

# Instalando php
 echo "PHP: Iniciando instalação do php ${VERSAO}..."
 apt install php${VERSAO} -y --quiet > /dev/null 2>&1
 apt --yes install php${VERSAO}-cli php${VERSAO}-fpm php${VERSAO}-mysql php${VERSAO}-zip php${VERSAO}-gd php${VERSAO}-mbstring php${VERSAO}-curl php${VERSAO}-xml php${VERSAO}-bcmath php${VERSAO}-imagick php${VERSAO}-intl php${VERSAO}-soap php${VERSAO}-pgsql > /dev/null 2>&1
 echo "PHP: php${VERSAO}-fpm foi instalado e está pronto para uso com Nginx"

# Instalar mysql
if [[ "$MYSQL" == "1"]]; then
 echo "MySQL: Iniciando a instalação do MySQL Server"
 apt-get --yes --quiet install mysql-server > /dev/null 2>&1
 mysql -e "create user admin_${int}@localhost IDENTIFIED WITH mysql_native_password BY '$password_db'" > /dev/null 2>&1
 mysql -e "GRANT ALL PRIVILEGES ON *.* TO admin_${int}@localhost" > /dev/null 2>&1
 mysql -e "FLUSH PRIVILEGES" > /dev/null 2>&1
cat > /root/.my.cnf << EOF
[client]
user=admin_${int}
password=$password_db
EOF
 echo "MySQL: Instalação do MySQL concluída com sucesso"
fi

wget https://github.com/fabwebbr/lemp_fw/raw/main/modelo-vhost-nginx.txt -O /root/modelo-vhost-nginx.txt

clear
echo "-----------------------------------------------------------------"
echo "                     Instalação concluída                        "
echo "-----------------------------------------------------------------"
echo ""
echo " Use o arquivo modelo 'modelo-vhost-nginx.txt' que está em seu "
echo " '/root/' para criar um domínio em seu servidor."
echo ""
echo " Os dados de acesso ao seu MySQL pelo terminal são:"
echo " "
echo " Servidor: localhost (Porta 3306)"
echo " Usuário: admin_${int}"
echo " Senha: $password_db"
echo " "
echo " Com essas credenciais você pode gerenciar seus bancos de dados."
echo " "
echo " As credenciais de acesso ao MySQL (acesso via CLI) estão salvas "
echo " no arquivo /root/.my.cnf "
echo "-----------------------------------------------------------------"