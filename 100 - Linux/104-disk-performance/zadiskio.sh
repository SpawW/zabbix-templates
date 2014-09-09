#! /bin/bash
#
# Name: zadiskio
#
# Checks IO Disk activity.
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
    echo "    $0 <FileSystem> ReadOps   -- Check Read Ops."
    echo "    $0 <FileSystem> ReadMs    -- Check Read Latency."
    echo "    $0 <FileSystem> WriteOps  -- Check Write Ops."
    echo "    $0 <FileSystem> WriteMs   -- Check Write Latency."
    echo "    $0 <FileSystem> IoProgress-- Current IO Requests."
    echo "    $0 <FileSystem> IoMs      -- Check IO Latency."
    echo "    $0 <FileSystem> ReadSectors       -- Check Read Sectors."
    echo "    $0 <FileSystem> WriteSectors      -- Check Write Sectors."

}

########
# Main #
########
#set -x

# Get source 
SOURCE=`mount  | grep " $1 " | awk -F/ '{print $3}' | awk '{print $1}'`;
if [[ "$SOURCE" == "mapper" ]]; then
  SOURCE=`mount  | grep " $1 " | awk -F/ '{print $4}' | awk '{print $1}' `;
#| awk -F- '{print $1}' `;
#echo $SOURCE;
#  SOURCE=` pvscan | grep $SOURCE | awk '{print $2}' | awk -F/ '{print $3}'`;
  SOURCE=$(ls -ltra /dev/mapper/ | grep $SOURCE | awk '{print $5$6}');
  TMP1=$(echo $SOURCE | awk -F, '{print $1}');
  TMP2=$(echo $SOURCE | awk -F, '{print $2}');
  SOURCE=$(cat /proc/diskstats | grep $TMP1 | grep "   $TMP2 " | awk '{print $3}');
#echo $SOURCE;
#exit
else
 # Inicio 20/08/2014
 # Adição feita por Werneck.costa@gmail.com
 # Adição de condição caso o sistema utilize o esquema de discos por ID:
 if [ "$SOURCE" == "disk" ]
 then
         SOURCE=$(blkid|grep -vi "swap"|grep `mount|grep " $1 "|grep "by-uuid"|cut -d '/' -f 5|cut -d ' ' -f 1`|cut -d ':' -f 1|cut -d '/' -f 3)
 # Fim 20/08/2014 - Werneck
fi
# 

if [[ $# ==  3 ]];then
    #Agent Mode
    VAR=$(cat /proc/diskstats | grep $SOURCE | head -1)
    CASE_VALUE=$2
elif [[ $# == 2 ]];then
    #External Script Mode
    VAR=$(cat /proc/diskstats | grep $SOURCE | head -1)
    CASE_VALUE=$2
else
    #No Parameter
    usage
    exit 0
fi

if [[ -z $VAR ]]; then
    echo "ZBX_NOTSUPPORTED"
    exit 1
fi

case $CASE_VALUE in
'ReadOps')
    echo "$VAR"|awk '{print $4}'
    rval=$?;;
'ReadMs')
    echo "$VAR"|awk '{print $7}'
    rval=$?;;
'ReadSectors')
    echo "$VAR"|awk '{print $6}'
    rval=$?;;

'WriteOps')
    echo "$VAR"|awk '{print $8}'
    rval=$?;;
'WriteMs')
    echo "$VAR"|awk '{print $11}'
    rval=$?;;
'WriteSectors')
    echo "$VAR"|awk '{print $10}'
    rval=$?;;
'IoProgress')
    echo "$VAR"|awk '{print $12}'
    rval=$?;;
'IoMs')
    echo "$VAR"|awk '{print $13}'
    rval=$?;;
*)
    usage
    exit $rval;;
esac

if [ "$rval" -ne 0 ]; then
      echo "ZBX_NOTSUPPORTED"
fi

exit $rval

#
# end

