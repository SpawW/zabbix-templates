<?php

global $VG_DEBUG;
$VG_DEBUG = (isset($_REQUEST['p_debug']) && $_REQUEST['p_debug'] == 'S' ? TRUE : FALSE );
if ($VG_DEBUG == TRUE) {
    error_reporting(E_ALL & ~E_NOTICE);
    ini_set('display_errors', '1');
}
include_once "../conf/zabbix.conf.php";
function debugInfo($p_mensagem, $p_debug = false, $p_cor = "gray") {
    global $VG_DEBUG;
    if ($p_debug == true || $VG_DEBUG == true) {
        echo '<div style="background-color:' . $p_cor . ';">' . $p_mensagem . "</div>";
    }
}
function conectaBD() {
    global $DB;
    $config_host = $DB['SERVER'];
    $config_user = $DB['USER'];
    $config_password = $DB['PASSWORD'];
    $config_db = $DB['DATABASE'];
    // Opens a connection to a mySQL server
    $connection = mysql_connect($config_host, $config_user, $config_password);
    if (!$connection) {
        die("Not connected : " . mysql_error());
    }

    // Set the active mySQL database
    $db_selected = mysql_select_db($config_db, $connection);
    if (!$db_selected) {
        die("Can\'t use db : " . $config_db . " - " . mysql_error());
    }
    mysql_query("SET names utf8;");
}

function preparaQuery($p_query) {
    debugInfo($p_query, $_REQUEST['p_debug'] == 'S');
    $result = mysql_query($p_query);
    if (!$result) {
        die("Invalid query: " . mysql_error());
        return 0;
    } else {
        return $result;
    }
}

function arraySelect($p_query) {
    $result = preparaQuery($p_query);
    $retorno = array();
    $cont = 0;
    while ($row = @mysql_fetch_assoc($result)) {
        $retorno[$cont] = $row;
        $cont++;
    }
    return $retorno;
}

conectaBD();
if ($_REQUEST['p_acao'] == "LLD") {
    $dados = arraySelect('show tables');
    foreach ($dados as $linha) {
        $json[count($json)]['{#NOME}'] = $linha['Tables_in_zabbix'];
    }
    echo json_encode(array('data'=>$json));
}
if ($_REQUEST['p_acao'] == "count") {
    echo valorCampo('select count(*) as id from '.$_REQUEST['p_tabela'], 'id');
}
?>