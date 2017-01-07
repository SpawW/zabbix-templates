#!/bin/bash
#-------------------------------------------------------
# author:       Adail Spinola <the.spaww@gmail.com>
# date:         05-jan-2016
#-------------------------------------------------------
#
# Variaveis de ambiente

PHPINI="/etc/php.ini"
# Instala Zabbix Server
SERVER="S";
# Instala Zabbix Proxy
PROXY="N";

# Criando e acessando o diretorio temporario de instalacao
mkdir /install 
cd /install

# Habilitando repositorio centos
rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm

# Atualizando pacotes e instalando os pre-req
yum -y update && yum -y groupinstall 'Development Tools' ; 
# Comuns
yum -y install wget net-snmp net-snmp-devel net-snmp-utils net-snmp-libs iksemel-devel zlib-devel libc-devel curl-devel automake libidn-devel openssl-devel rpm-devel OpenIPMI-devel libssh2-devel make fping ; 

if [ $PROXY == "S" ]; then
	# BD para o proxy
	yum -y install sqlite-devel sqlite

fi

if [ $SERVER == "S" ]; then
	# Suporte BD com MariaDB
	yum -y install mariadb-server mariadb-devel

	# Instalando php 5.4
	yum -y install php php-bcmath php-gd php-mbstring  php-xml php-ldap php-mysql php-ldap php-mysql httpd --skip-broken
	
	# Configurando o php.ini
	sed -i "s/date.timezone/;date.timezone/" $PHPINI;
	sed -i "s/max_execution_time/;max_execution_time/" $PHPINI;
	sed -i "s/max_input_time/;max_input_time/" $PHPINI;
	sed -i "s/post_max_size/;post_max_size/" $PHPINI;

	echo "date.timezone =America/Sao_Paulo" >> $PHPINI;
	echo "max_execution_time = 300" >> $PHPINI;
	echo "max_input_time = 300" >> $PHPINI;
	echo "post_max_size = 16M" >> $PHPINI;
	echo "always_populate_raw_post_data=-1" >> $PHPINI

	# Garantindo o autostart de mysql e apache
	systemctl enable httpd.service
	systemctl enable mariadb.service

	systemctl restart httpd.service
	systemctl restart mariadb.service
	
fi

# Criando o usuario zabbix
useradd zabbix -s /bin/false


# Instala o iptables
yum install -y iptables-services
	systemctl enable iptables.service
/usr/libexec/iptables/iptables.init save

# Desabilita o  SELINUX
sed -i 's/enforcing/disabled/g' /etc/selinux/config
setenforce 0

systemctl disable firewalld
systemctl stop firewalld
#vim /etc/sysconfig/iptables
iptables -F

/usr/libexec/iptables/iptables.init save

#Alterar MANUALMENTE o arquivo /etc/sysconfig/iptables adicionando as regras de iptables caso nao queira deixar tudo escancarado
iptables -A INPUT -p udp -m udp --dport 631 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 10050 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 10051 -j ACCEPT
# Estas portas nao sao necessarias para o Zabbix, foram adicionadas para facilitar transmissao de arquivos entre a VM e a estacao do aluno
iptables -A INPUT -p tcp -m tcp --dport 137 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 138 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 139 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 445 -j ACCEPT

# Salva as novas regras
/usr/libexec/iptables/iptables.init save

