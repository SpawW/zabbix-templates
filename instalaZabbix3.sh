#!/bin/bash
#-------------------------------------------------------
# author:       Adail Spinola <the.spaww@gmail.com>
# date:         05-jan-2016
# Update Log:
# 20160829 - Auto Update of Date in virtual machine
# 20161215 - Prompt variables values
#-------------------------------------------------------
#
# Variaveis de ambiente

PHPINI="/etc/php.ini"
# Padrao para producao
ZBX_VER="3.2.3";
WWW_PATH="/var/www/html/";

# Instala Zabbix Server
SERVER="S";
# Instala Zabbix Proxy
PROXY="N";

read -p "Instalar o servidor Zabbix: " -e -i "$SERVER" SERVER
read -p "Instalar o proxy Zabbix: " -e -i "$PROXY" PROXY


if [ $SERVER == "S" ]; then
	SENHA="za159753";
	SENHAROOT="za159753_root";
	NOMEBANCO="zbx_db3";
	#USUARIODB="zbx_db3";
	NOMEINSTALACAO="Minha ilha de monitoração Zabbix";
	read -p "MySQL - Banco de dados do Zabbix: " -e -i "$NOMEBANCO" NOMEBANCO
	USUARIODB=$NOMEBANCO;
	read -p "MySQL - Senha do Zabbix: " -e -i "$SENHA" SENHA
	read -p "MySQL - Senha do Root: " -e -i "$SENHAROOT" SENHAROOT
	read -p "Zabbix - Nome da empresa\/projeto: " -e -i "$NOMEINSTALACAO" NOMEINSTALACAO
fi

if [ $PROXY == "S" ]; then
	read -p "Servidor Zabbix - endereço: " -e -i "127.0.0.1" ZABBIXSERVER
	read -p "Servidor Zabbix - porta: " -e -i "10051" ZABBIXPORT
	read -p "PROXY Zabbix - porta: " -e -i "10051" PROXYPORT
	read -p "Proxy ICMP - quantidade de processos: " -e -i "5" PROXYICMP
	read -p "Proxy Discovery - quantidade de processos: " -e -i "3" PROXYDISCOVERY
	read -p "Proxy Nome: " -e -i "meu_proxy1" PROXYNAME
	
fi
# Atualizando a data e hora do servidor
date -s "$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g') -0000"

# Criando e acessando o diretorio temporario de instalacao
mkdir /install 
cd /install

# Download da versao stable
#URL_DOWN="http://ufpr.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$ZBX_VER/zabbix-$ZBX_VER.tar.gz";
URL_DOWN="http://netix.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$ZBX_VER/zabbix-$ZBX_VER.tar.gz";

#curl $URL_DOWN -o zabbix.tgz
wget $URL_DOWN -O zabbix.tgz
# Versao desenvolvimento
tar -xzvf zabbix.tgz

if [ $SERVER == "S" ]; then
	# Garantindo o autostart de mysql e apache
	systemctl enable httpd.service
	systemctl enable mariadb.service

	systemctl restart httpd.service
	systemctl restart mariadb.service
	#Definindo a senha do root
	/usr/bin/mysqladmin -u root password $SENHAROOT;

	# Configurando o banco de dados
	echo "create database $NOMEBANCO character set utf8;" | mysql -uroot -p$SENHAROOT
	echo "GRANT ALL PRIVILEGES ON $NOMEBANCO.* TO $USUARIODB@localhost IDENTIFIED BY '$SENHA' WITH GRANT OPTION;" | mysql -uroot -p$SENHAROOT

	# Populando a base de dados
	cd /install/zabbix-$ZBX_VER
	cat database/mysql/schema.sql | mysql -u $USUARIODB -p$SENHA $NOMEBANCO && cat database/mysql/images.sql | mysql -u $USUARIODB -p$SENHA $NOMEBANCO && cat database/mysql/data.sql | mysql -u $USUARIODB -p$SENHA $NOMEBANCO;

	# Criando o frontend
	cd /install/zabbix-$ZBX_VER
	rm $WWW_PATH/index.html 
	mkdir "$WWW_PATH";
	cp -Rpv frontends/php/* $WWW_PATH

	# Criando o arquivo de configuracao do frontend
	echo -e "<?php
// Zabbix GUI configuration file. - Created by Adail Horst
global \$DB;

\$DB['TYPE']				= 'MYSQL';
\$DB['SERVER']			= 'localhost';
\$DB['PORT']				= '0';
\$DB['DATABASE']			= '$NOMEBANCO';
\$DB['USER']				= '$USUARIODB';
\$DB['PASSWORD']			= '$SENHA';
// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA']			= '';

\$ZBX_SERVER				= 'localhost';
\$ZBX_SERVER_PORT		= '10051';
\$ZBX_SERVER_NAME		= '$NOMEINSTALACAO';

\$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;
?>
" > $WWW_PATH/conf/zabbix.conf.php

	chmod 755 $WWW_PATH/conf/zabbix.conf.php
	
fi 

if [ $PROXY == "S" ]; then
	# Populando banco de dados zabbix_proxy
	cd /install/zabbix-$ZBX_VER/database/sqlite3
	mkdir /var/lib/sqlite/
	sqlite3 /var/lib/sqlite/zabbix.db < schema.sql
	chown -R zabbix:zabbix /var/lib/sqlite/
fi

# Compilando os binarios
cd /install/zabbix-$ZBX_VER
# Configurando inicializacao do agente
cp -Rpv misc/init.d/fedora/core5/zabbix_agentd /etc/init.d/

if [ $SERVER == "S" ]; then
	# Para Server e agente
	./configure --enable-server --enable-agent --with-mysql --with-net-snmp  --with-libcurl --with-openipmi && make install
	# Configurando inicializacao do server
	cp -Rpv misc/init.d/fedora/core5/zabbix_server /etc/init.d/
		
	chmod +x /etc/init.d/za*
	chkconfig --add zabbix_server
	chkconfig --level 35 zabbix_server on
	
	# Mudando banco e senha para o novo nome do zbx3 para testes
	curl -s https://raw.githubusercontent.com/zabbix-brasil/livrozabbix2014/master/Capitulo_2/criaConfServer.sh -o /install/criaConfServer.sh
	sed -i "s/zabbix-2./zabbix-3./g"  /install/criaConfServer.sh
	sed -i "s/zbx_db/$NOMEBANCO/g" /install/criaConfServer.sh
	sed -i "s/creative2014/$SENHA/g" /install/criaConfServer.sh
	sed -i "s/creative2014_root/$SENHA_ROOT/g" /install/criaConfServer.sh
	sh /install/criaConfServer.sh
	# Reinicia (ou no caso inicia...) o zabbix_server
	service zabbix_server restart
fi

if [ $PROXY == "S" ]; then
	# Para proxy e agente
	./configure --enable-proxy --enable-agent --with-sqlite3 --with-net-snmp  --with-libcurl --with-openipmi  &&  make install
	# Configurando inicializacao do server
	cp -Rpv misc/init.d/fedora/core5/zabbix_server /etc/init.d/zabbix_proxy
	sed -i "s/Server/Proxy/g" /etc/init.d/zabbix_proxy
	sed -i "s/server/proxy/g" /etc/init.d/zabbix_proxy
	PROXY_CONF="/usr/local/etc/zabbix_proxy.conf";
	sed -i "s/^DBName/#DBName/g" $PROXY_CONF;
	sed -i "s/^Server=/#Server=/g" $PROXY_CONF;
	sed -i "s/^ServerPort=/#ServerPort=/g" $PROXY_CONF;
	sed -i "s/^StartPingers=/#StartPingers=/g" $PROXY_CONF;
	sed -i "s/^StartDiscoverers=/#StartDiscoverers=/g" $PROXY_CONF;
	sed -i "s/^ListenPort=/#ListenPort=/g" $PROXY_CONF;
	sed -i "s/^Hostname=/#HostName=/g" $PROXY_CONF;
	echo "DBName=/var/lib/sqlite/zabbix.db" >> $PROXY_CONF;
	echo "ServerPort=$ZABBIXPORT" >>  $PROXY_CONF;
	echo "Server=$ZABBIXSERVER" >>  $PROXY_CONF;
	echo "StartPingers=$PROXYICMP" >> $PROXY_CONF;
	echo "StartDiscoverers=$PROXYDISCOVERY" >> $PROXY_CONF;
	echo "ListenPort=$PROXYPORT" >> $PROXY_CONF;
	echo "Hostname=$PROXYNAME" >> $PROXY_CONF;
		
	chmod +x /etc/init.d/za*
	chkconfig --add zabbix_proxy
	chkconfig --level 35 zabbix_proxy on
	service zabbix_proxy restart
	
fi

# Baixando os scripts de configuracao do agente e do servidor, conforme livro
cd /install
curl -s https://raw.githubusercontent.com/zabbix-brasil/livrozabbix2014/master/Capitulo_2/configuraAgente.sh -o  configuraAgente.sh
sed -i "s/zabbix-2./zabbix-3./g"   configuraAgente.sh
sh configuraAgente.sh
chkconfig --add zabbix_agentd
chkconfig --level 35 zabbix_agentd on



# Configurar zabbix_server.conf e zabbix_proxy.conf
service zabbix_agentd restart

