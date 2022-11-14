#!/bin/bash
#
# Antes de usar este script você precisa instalar o b2 com o comando: pip3 install --upgrade b2
# Você precisa ter o python e o pip3 instalados para executar o comando acima
#
# Após o comando acima, autentique no backblaze com o comando: b2 authorize-account <APPLICATIO_KEY_ID> <APPLICATION_KEY>
#
#######################################

# Qual diretório deseja fazer backup?
DIRETORIO_BKP="/var/www"

# Backup de qual banco de dados? (Se quiser fazer de todo o BD, informar --all-databases)
BANCO_BKP="--all-databases"

# Informaçoes de conexão ao BD
HOST_BD="localhost"
USER_BD="root"
PASS_BD="..."

# Informações backblaze
NOME_BUCKET="exemplo_meu_bucket1"

##### Backup
DATA1="`date +%m-%m-%Y_%H`"

# Sincronizando arquivos no diretório temporário
mkdir /root/.tmp && mkdir /root/.tmp/${DATA1}
cd /root/.tmp/
rsync -azh ${DIRETORIO_BKP} /root/.tmp/${DATA1}/

# Backup do BD
mkdir /root/.tmp/${DATA1}/database/ && cd /root/.tmp/${DATA1}/database/
mysqldump -h${HOST_BD} -u${USER_BD} -p${PASS_BD} ${BANCO_BKP} > database-${DATA1}.sql

# Zipa os arquivos do .tmp
cd /root/.tmp/
tar -czf fullbackup-${DATA1}.tar.gz ${DATA1}
rm -rf /root/.tmp/${DATA1}

# Upload para b2
b2 upload-file --noProgress ${NOME_BUCKET} /root/.tmp/fullbackup-${DATA1}.tar.gz fullbackup-${DATA1}.tar.gz
