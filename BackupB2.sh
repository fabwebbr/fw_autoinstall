#!/bin/bash
#
# Antes de usar este script você precisa instalar o b2 com o comando: pip3 install --upgrade b2
# Você precisa ter o python e o pip3 instalados para executar o comando acima
#
# Após o comando acima, autentique no backblaze com o comando: b2 authorize-account <APPLICATIO_KEY_ID> <APPLICATION_KEY>
#
#######################################

# Qual diretório deseja fazer backup?
DIRETORIO_BKP1="/home/"
DIRETORIO_BKP2="/root/"
DIRETORIO_BKP3="/etc/apache2/"

# Backup de qual banco de dados? (Se quiser fazer de todo o BD, informar --all-databases)
BANCO_BKP="NOMED"

# Informaçoes de conexão ao BD
HOST_BD="localhost"
USER_BD="root"
PASS_BD="..."

# Informações backblaze
NOME_BUCKET="exemplo_meu_bucket1"

##### Backup
DATA1="`date +%m-%m-%Y_%H`"

# Sincronizando arquivos no diretório temporário
mkdir /backups/.tmp && mkdir /backups/.tmp/${DATA1}
cd /backups/.tmp/
mkdir home && rsync -azh ${DIRETORIO_BKP1} /backups/.tmp/${DATA1}/home/
mkdir backups && rsync -azh ${DIRETORIO_BKP2} /backups/.tmp/${DATA1}/root/
mkdir apache && rsync -azh ${DIRETORIO_BKP3} /backups/.tmp/${DATA1}/apache/

# Backup do BD
mkdir /backups/.tmp/${DATA1}/database/ && cd /backups/.tmp/${DATA1}/database/
sudo -u postgres /usr/bin/pg_dump -O ${BANCO_BKP} > database-${DATA1}.sql
mv /var/lib/postgresql/database-${DATA1}.sql /backups/.tmp/${DATA1}/database/

# Zipa os arquivos do .tmp
cd /backups/.tmp/
tar -czf fullbackup-${DATA1}.tar.gz ${DATA1}
rm -rf /backups/.tmp/${DATA1}

# Upload para b2
b2 upload-file --noProgress ${NOME_BUCKET} /backups/.tmp/fullbackup-${DATA1}.tar.gz fullbackup-${DATA1}.tar.gz

rm -rf /backups/.tmp

exit;
