#!/usr/bin/env node
'use strict';

// Genera dati/squadriglie.json a partire dall'elenco ragazzi in CSV
// (export con separatore ';' e prima riga di intestazione, come il vecchio
// anagrafica_da_csv.php che questo script sostituisce).
//
// Uso:     node anagrafica/genera_anagrafica.js [--input <csv>] [--output <json>]
// Anonimo: ANONIMO=1 -> solo i nomi delle squadriglie, members vuoti
//          (nessun dato ragazzo nel json: sito condivisibile senza anagrafica).
//
// Lo script gira nell'immagine del generatore (make anagrafica) ed è montato
// come volume: si può modificare a mano senza rifare make init.

const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');
const { transliterate } = require('transliteration');

const CSV_DEFAULT = 'anagrafica/elenco_ragazzi.csv';
const OUTPUT_DEFAULT = 'dati/squadriglie.json';
const SEPARATORE = ';';
const COLONNE_OBBLIGATORIE = ['squadriglia', 'nome', 'cognome'];

// Esce con un messaggio d'errore azionabile, nello stile della diagnostica
// di avvio del generatore (niente stack trace).
function erroreExit(righe) {
  console.error('');
  for (const riga of righe) {
    console.error(riga);
  }
  console.error('');
  process.exit(1);
}

function aiuto() {
  const uso = [
    'Uso: node anagrafica/genera_anagrafica.js [--input <csv>] [--output <json>]',
    '',
    'Legge l\'elenco ragazzi (separatore \';\', prima riga di intestazione) e',
    'scrive il json delle squadriglie per il generatore del sito.',
    "Con ANONIMO=1 nel json finiscono solo i nomi delle squadriglie (members vuoti).",
    '',
    `  --input    CSV in ingresso (default: ${CSV_DEFAULT})`,
    `  --output   json in uscita (default: ${OUTPUT_DEFAULT})`
  ];
  console.log(uso.join('\n'));
}

function parseArgomenti(argv) {
  const opzioni = { input: CSV_DEFAULT, output: OUTPUT_DEFAULT };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--input' && argv[i + 1]) {
      opzioni.input = argv[++i];
    } else if (argv[i] === '--output' && argv[i + 1]) {
      opzioni.output = argv[++i];
    } else if (argv[i] === '--help' || argv[i] === '-h') {
      opzioni.aiuto = true;
    } else {
      erroreExit([
        `Argomento non riconosciuto: ${argv[i]}`,
        'Usa --help per l\'uso.'
      ]);
    }
  }
  return opzioni;
}

// "Dt Nascita" -> "dtnascita": stesse chiavi del json di sempre
// (il PHP faceva strtolower senza spazi sull'intestazione).
function normalizzaChiave(intestazione) {
  return String(intestazione).trim().replace(/\s+/g, '').toLowerCase();
}

// Parsa il contenuto del CSV: intestazione normalizzata + righe-oggetto.
// Tollerante sulle righe vuote, severo sul numero di colonne (diagnosi chiara).
function leggiCsv(contenuto) {
  const records = parse(contenuto, {
    delimiter: SEPARATORE,
    quote: '"',
    bom: true,
    skip_empty_lines: true
  });
  if (records.length === 0) {
    return { intestazione: [], righe: [] };
  }
  const intestazione = records[0].map(normalizzaChiave);
  const righe = records.slice(1).map((campi) => {
    const riga = {};
    intestazione.forEach((chiave, i) => { riga[chiave] = campi[i]; });
    return riga;
  });
  return { intestazione, righe };
}

// Colonne obbligatorie: senza di loro il json non avrebbe senso.
function validaIntestazione(intestazione) {
  for (const colonna of COLONNE_OBBLIGATORIE) {
    if (!intestazione.includes(colonna)) {
      erroreExit([
        `Anagrafica: colonna obbligatoria mancante nel CSV: '${colonna}'`,
        `Intestazione trovata: ${intestazione.join(', ') || '(nessuna)'}`,
        "L'export dell'elenco ragazzi deve avere le colonne Squadriglia, Nome e Cognome."
      ]);
    }
  }
}

function leggiInput(percorsoCsv) {
  if (!fs.existsSync(percorsoCsv)) {
    erroreExit([
      `Anagrafica: elenco ragazzi non trovato: ${percorsoCsv}`,
      "Copiaci l'export CSV dell'elenco dell'anno (separatore ';', vedi Readme §2).",
      `Per una prova rapida: cp anagrafica/elenco_ragazzi_example.csv ${percorsoCsv}`
    ]);
  }
  let contenuto;
  try {
    contenuto = fs.readFileSync(percorsoCsv, 'utf8');
  } catch (err) {
    erroreExit([
      `Anagrafica: non riesco a leggere ${percorsoCsv} (${err.code || err.message})`,
      'Controlla i permessi del file.'
    ]);
  }
  let csv;
  try {
    csv = leggiCsv(contenuto);
  } catch (err) {
    erroreExit([
      `Anagrafica: CSV non valido: ${percorsoCsv}`,
      err.message
    ]);
  }
  validaIntestazione(csv.intestazione);
  return csv;
}

// Scrittura atomica: prima tutto su un .tmp, poi il rename. Un'eventuale
// interruzione non lascia un squadriglie.json a metà (il generatore legge
// quel file all'avvio di ogni build).
function scriviJson(percorso, squadriglie) {
  const tmp = `${percorso}.tmp`;
  fs.mkdirSync(path.dirname(percorso), { recursive: true });
  fs.writeFileSync(tmp, `${JSON.stringify(squadriglie)}\n`);
  fs.renameSync(tmp, percorso);
}

function main() {
  const opzioni = parseArgomenti(process.argv.slice(2));
  if (opzioni.aiuto) {
    aiuto();
    return;
  }
  const csv = leggiInput(opzioni.input);
  const anonimo = process.env.ANONIMO === '1';

  console.error(`anagrafica: letti ${csv.righe.length} ragazzi da ${opzioni.input}${anonimo ? ' (modalità anonima)' : ''}`);

  const squadriglie = generaSquadriglie(csv.righe, { anonimo });

  if (Object.keys(squadriglie).length === 0) {
    console.error('anagrafica: warning: nessun ragazzo nel CSV, squadriglie vuote');
  } else if (!anonimo) {
    // una squadriglia da un solo ragazzo è quasi sempre un typo nella
    // colonna Squadriglia del CSV (es. BLU vs BLU2)
    for (const nome of Object.keys(squadriglie)) {
      if (Object.keys(squadriglie[nome].members).length === 1) {
        console.error(`anagrafica: warning: la squadriglia '${nome}' ha un solo ragazzo: controlla eventuali typo nella colonna 'Squadriglia' del CSV`);
      }
    }
  }

  scriviJson(opzioni.output, squadriglie);
  console.error(`anagrafica: scritto ${opzioni.output} (${Object.keys(squadriglie).length} squadriglie)`);
}

// Prima lettera maiuscola (equivalente di ucfirst in PHP).
function ucfirst(testo) {
  return testo ? testo.charAt(0).toUpperCase() + testo.slice(1) : testo;
}

// Nome/cognome in forma leggibile: iniziale maiuscola per parola. Sulla
// parola singola tutto viene prima passato in minuscolo (accentate comprese),
// come mb_ucwords del vecchio PHP.
function maiuscolizza(nome) {
  const parole = String(nome).trim().split(/\s+/).filter((p) => p.length > 0);
  if (parole.length === 0) {
    return '';
  }
  if (parole.length > 1) {
    return parole.map(ucfirst).join(' ');
  }
  return ucfirst(parole[0].toLowerCase());
}

// Id ragazzo: traslitterazione ASCII, minuscolo, senza spazi né apostrofi.
// È la chiave del member nel json E il nome file della pagina ragazzo
// (dvd/angolisq): unica fonte di verità, così link e pagina coincidono.
function idRagazzo(nome, cognome) {
  const unito = (String(nome).trim() + String(cognome).trim()).replace(/\s+/g, '');
  return transliterate(unito, { trim: false })
    .toLowerCase()
    .replace(/['’]/g, '')
    .replace(/\s+/g, '');
}

// Costruisce le squadriglie dalle righe del CSV.
// - reale: una squadriglia per ogni ragazzo, members con tutti i campi;
// - anonima: solo i nomi delle squadriglie, members vuoti.
// L'ordine è quello di prima apparizione nel CSV (oggi dava l'elenco
// hardcoded "per anzianità" del vecchio PHP).
function generaSquadriglie(righe, opzioni) {
  const anonimo = !!(opzioni && opzioni.anonimo);
  const squadriglie = {};
  for (const riga of righe) {
    const valori = Object.values(riga).map((v) => String(v == null ? '' : v).trim());
    if (valori.every((v) => v === '')) {
      continue; // riga completamente vuota: la si tollera
    }
    const squadriglia = String(riga.squadriglia || '').trim().toLowerCase();
    if (!Object.prototype.hasOwnProperty.call(squadriglie, squadriglia)) {
      squadriglie[squadriglia] = { name: squadriglia, members: {} };
    }
    if (anonimo) {
      continue; // modalità anonima: nessun dato ragazzo nel json
    }
    const ragazzo = {};
    for (const [chiave, valore] of Object.entries(riga)) {
      ragazzo[chiave] = String(valore == null ? '' : valore).toLowerCase();
    }
    ragazzo.nome = maiuscolizza(ragazzo.nome);
    ragazzo.cognome = maiuscolizza(ragazzo.cognome);
    squadriglie[squadriglia].members[idRagazzo(ragazzo.nome, ragazzo.cognome)] = ragazzo;
  }
  return squadriglie;
}

module.exports = {
  normalizzaChiave,
  leggiCsv,
  validaIntestazione,
  maiuscolizza,
  idRagazzo,
  generaSquadriglie
};

if (require.main === module) {
  main();
}
