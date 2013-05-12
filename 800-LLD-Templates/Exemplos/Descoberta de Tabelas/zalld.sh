#! /bin/bash
#
# Name: zalld
#
# Custom LLD SAmple.
#
# Author: Adail Horst
#
# Version: 1.0
#
 
zaver="1.0"
rval=0
 
function usage()
{
    echo "zadiskio version: $zaver $#"
    echo "usage:"
    echo "    LLD -- Retorna a lista de tabelas."
    echo "    count,<TABELA> -- retorna a quantidade de linhas de uma tabela."

}
 
########
# Main #
########
#set -x
OPCAO=$1;
case $OPCAO in
'LLD')
    curl http://localhost/extras/lldBasesMySQL.php?p_acao=LLD;
;;
'count')
    curl "http://localhost/extras/lldBasesMySQL.php?p_acao=count&p_tabela=$2";
;;
esac
 
 
exit $rval
 
#
# end 

