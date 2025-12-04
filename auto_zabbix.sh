#!/bin/bash
##########################################################################
#
# Script para fazer instalação e configuração automática do zabbix-agent
#
##########################################################################

# IP do Zabbix-Server
SRVIP="IP-AQUI"

# Nome do servidor
SRVNAME="$(hostname -f)"

##########################################################################
#
# Não edite depois daqui
#

Concluir(){
    IP=`curl http://ifconfig.me`
    clear
    echo "O IP deste servidor é: $IP"
    echo "Adicione o host no servidor zabbix com o Hostname $SRVNAME"
    read -p "Pressione [ENTER] quando já tiver adicionado o host no servidor zabbix..." pronto
    echo "Pronto."
    systemctl enable zabbix-agent
    systemctl restart zabbix-agent
    exit
}

if [ -n "$(command -v yum)" ]; then
 yum install zabbix-agent -y
 systemctl enable zabbix-agent
 /usr/bin/sed -i "s/Server=127.0.0.1/Server=$SRVIP/g" /etc/zabbix_agentd.conf
 /usr/bin/sed -i "s/ServerActive=127.0.0.1/ServerActive=$SRVIP/g" /etc/zabbix_agentd.conf
 /usr/bin/sed -i "s/Hostname=Zabbix server/Hostname=$SRVNAME/g" /etc/zabbix_agentd.conf
 Concluir
fi
if [ -n "$(command -v apt)" ]; then
 apt install zabbix-agent -y
 systemctl enable zabbix-agent
 /usr/bin/sed -i "s/Server=127.0.0.1/Server=$SRVIP/g" /etc/zabbix/zabbix_agentd.conf
 /usr/bin/sed -i "s/ServerActive=127.0.0.1/ServerActive=$SRVIP/g" /etc/zabbix/zabbix_agentd.conf
 /usr/bin/sed -i "s/Hostname=Zabbix server/Hostname=$SRVNAME/g" /etc/zabbix/zabbix_agentd.conf
 Concluir
fi
