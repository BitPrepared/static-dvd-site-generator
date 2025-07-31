<?php

//display error message if any
ini_set('display_startup_errors',1);
ini_set('display_errors',1);
setlocale(LC_ALL, 'it_IT.UTF-8');
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
        $name = mb_ucwords($name);
    }
}

function mb_ucfirst($string, $encoding = 'UTF-8') {
    $firstChar = mb_substr($string, 0, 1, $encoding);
    $rest = mb_substr($string, 1, null, $encoding);
    return mb_strtoupper($firstChar, $encoding) . $rest;
}

function mb_ucwords($string, $encoding = 'UTF-8') {
    $words = explode(' ', $string);
    foreach ($words as &$word) {
        $word = mb_ucfirst(mb_strtolower($word, $encoding), $encoding);
    }
    return implode(' ', $words);
}

function safe_transliterate($str) {
    $fallbackMap = [
        'À' => 'A', 'É' => 'E', 'Ï' => 'I', // etc.
        'à' => 'a'
    ];
    $str = strtr($str, $fallbackMap);
    return iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $str);
}

function normalize_ascii($str) {
    if (!mb_check_encoding($str, 'UTF-8')) {
        $str = mb_convert_encoding($str, 'UTF-8', 'auto');
    }

    if (function_exists('transliterator_transliterate')) {
        return transliterator_transliterate('Any-Latin; Latin-ASCII', $str);
    }

    $converted = safe_transliterate($str);

    if ($converted === false || strpos($converted, '?') !== false && strpos($str, '?') === false) {
        throw new Exception("Caratteri non convertibili trovati: $str");
    }

    return $converted;
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

        $fullname = strtolower(normalize_ascii(join('',explode(' ',trim($data['nome'].$data['cognome'])))));
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

// Filtra le chiavi con array non vuoti
$grp = array_filter($grp, function($value) {
    return !empty($value['members']);
});

echo json_encode($grp);

//echo json_encode($app_suddivisione);
