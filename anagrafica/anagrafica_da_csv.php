<?php

//display error message if any
ini_set('display_startup_errors',1);
ini_set('display_errors',1);
error_reporting(-1);
date_default_timezone_set('Europe/Rome');

function uppurcase_name(&$name){
    $multi_name = explode(' ',trim($name));
    if ( count($multi_name) > 1 ){
        array_walk($multi_name, function(&$item, $key){
            $item = ucfirst($item);
        });
        $name = join(' ',$multi_name);
    } else {
        $name = ucfirst($name);
    }
}

//open csv file
if (($handle = fopen("./elenco_ragazzi.csv", "r")) !== FALSE) {

    $flag = true;
    $id=1;
    $keys = [];
    $grp = [
        'oro' => [ 'name' => 'oro' , 'members' => [] ],
        'arancio' => [ 'name' => 'arancio' , 'members' => [] ],
        'blu' => [ 'name' => 'blu' , 'members' => [] ],
        'rosso' => [ 'name' => 'rosso' , 'members' => [] ]
    ];
    
    $app_suddivisione = [
        'ragazzi' => []
    ];

    //fetch data from each row
    while (($row = fgetcsv($handle, 0, ";")) !== FALSE) {
        if ($flag) {
            $flag = false;
            foreach($row as $value){
                $keys[] = strtolower(join('',explode(' ',trim($value))));
            }
            continue;
        }

        $data = array_combine($keys, $row);
        array_walk($data, function(&$item, $key){
            $item = strtolower($item);
        });
        uppurcase_name($data['nome']);
        uppurcase_name($data['cognome']);

        $fullname = strtolower(join('',explode(' ',trim($data['nome'].$data['cognome']))));
        # no apici, no spazi
        $fullname = str_replace('\'','', $fullname);
        $fullname = str_replace(' ','', $fullname);

        $sqname = $data['squadriglia'];
        $grp[$sqname]['members'][$fullname] = $data;

        $app_suddivisione['ragazzi'][] = [
            'nome' => $data['nome'],
            'cognome' => $data['cognome'],
            'squadriglia' => $data['squadriglia']
        ];
    }

    fclose($handle);
}

echo json_encode($grp);

echo json_encode($app_suddivisione);
