#!/usr/bin/php
<?php

//--- Config

/*
 * Database info
 */
define('DB_CONN_STR', 'mysql:host=db.strings.dfw01.int.strings-infra.net;dbname=strings');
define('DB_USER', '');
define('DB_PASS', '');


//--- Main

$organizationId = ???;
$dbConn = dbConnect(DB_CONN_STR, DB_USER, DB_PASS);

$query = "
    SELECT *
    FROM hiera
    WHERE organization_id = {$organizationId}
";

$results = fetchAll($dbConn, $query);

foreach($results as $row) {

    $hieraKey = $row['hiera_key'];
    $var = $row['var'];
    $val = json_decode($row['val'], true);
    if($val === null)
        $val = $row['val'];

    $file = $hieraKey . ".json";

    if(!file_exists($file)){
        $parentDir = dirname($file);
        exec("mkdir -p $parentDir");
        file_put_contents($file, '{}');
    }

    $data = json_decode(file_get_contents($file), true);
    $data[$var] = $val;

    file_put_contents($file, json_encode($data));
}


//--- Functions

function dbConnect($connStr, $user, $pass){

    $conn = new PDO($connStr, $user, $pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    return $conn;
}

function fetch($conn, $query,$queryParameters=array()){

    $s = query($conn, $query, $queryParameters);
    return $s->fetch();
}

function fetchAll($conn,$query,$queryParameters=array(),$index=false,$callback=false){

    $s = query($conn,$query,$queryParameters);
    return $s->fetchAll();
}

function query($conn,$query,$queryParameters=array()){

    $statement = $conn->prepare($query);
    $statement->execute($queryParameters);
    return $statement;
}
