#!/usr/bin/php
<?php

//--- Config

/*
 * Database info
 */
define('DB_CONN_STR', 'mysql:host=db.strings.dfw01.int.strings-infra.net;dbname=strings');
define('DB_USER', 'app_demo_cleanup');
define('DB_PASS', '');

/*
 * API url
 */
define('API_URL', 'https://api.strings.dfw01.int.strings-infra.net');

/*
 * Organization ids of all of the demo accounts
 * Note: these values are not escaped
 */
$demoOrgIds = array(4, 5, 6);

/*
 * Delete formations that have existed for this long
 * Note: this value is not escaped
 */
$deleteAfter = '80 minute';


//--- Main

$dbConn = dbConnect(DB_CONN_STR, DB_USER, DB_PASS);

$query = "
    SELECT *
    FROM formation as f
    WHERE f.organization_id IN (" . implode(',',$demoOrgIds) . ") and
      f.created < DATE_SUB(NOW(), INTERVAL $deleteAfter)
";

$results = fetchAll($dbConn, $query);

foreach($results as $formation) {

    $organizationId = $formation['organization_id'];
    $formationId = $formation['id'];

    $query = "
        INSERT INTO queued_job (
          organization_id, http_method, url, body, timeout_secs,
          remaining_retries, retry_delay_secs
        )
        values
        (
          :organization_id,
          'POST',
          :url,
          null,
          90,
          40,
          30
        )
    ";

    $queryParams = array(
        ':organization_id' => $organizationId,
        ':url' => API_URL . "/Formations/delete/$formationId",
    );

    query($dbConn, $query, $queryParams);
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
