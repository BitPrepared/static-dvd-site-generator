#!/usr/bin/env node
'use strict';

// Genera dati/squadriglie.json incrociando l'elenco ragazzi in CSV (export
// con separatore ';' e prima riga di intestazione) con il registro dei
// codici delle foto segnaletiche scritto dall'import
// (anagrafica/registro_segnaletiche.csv, change foto-segnaletiche-codificate):
// se il ragazzo è nel registro la chiave del member è il suo codice
// (es. mr1_blu), altrimenti l'id da nome+cognome come prima.
//
// Uso:     node anagrafica/genera_anagrafica.js [--input <csv>] [--output <json>] [--registro <csv>]
// Anonimo: ANONIMO=1 -> solo nomi squadriglie; col registro anche i soli
//          codici dei ragazzi con foto ({codice:{ini:"M. R."}}, iniziali
//          puntate per la griglia della pagina squadriglia — nessun altro
//          dato anagrafico nel json).
// Valvola: senza file di registro (import mai lanciato) le chiavi restano
//          nomecognome, identiche alla pipeline precedente.
//
// Lo script gira nell'immagine del generatore (make anagrafica) ed è montato
// come volume: si può modificare a mano senza rifare make init.

const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');
const { transliterate } = require('transliteration');

const CSV_DEFAULT = 'anagrafica/elenco_ragazzi.csv';
// Registro dei codici delle foto segnaletiche (change
// foto-segnaletiche-codificate): scritto dall'import, qui solo letto. Se
// manca la valvola di sicurezza mantiene le chiavi legacy nomecognome.
const REGISTRO_DEFAULT = 'anagrafica/registro_segnaletiche.csv';
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
    'Uso: node anagrafica/genera_anagrafica.js [--input <csv>] [--output <json>] [--registro <csv>]',
    '',
    'Legge l\'elenco ragazzi (separatore \';\', prima riga di intestazione), lo',
    'incrocia col registro dei codici delle foto segnaletiche e scrive il json',
    'delle squadriglie per il generatore del sito.',
    'Senza registro le chiavi restano nome+cognome come nella pipeline precedente.',
    "Con ANONIMO=1 il json non contiene dati anagrafici: solo squadriglie e,",
    'se c\'è il registro, i codici dei ragazzi con foto importata con le',
    'iniziali puntate (ini: "M. R.").',
    '',
    `  --input     CSV in ingresso (default: ${CSV_DEFAULT})`,
    `  --output    json in uscita (default: ${OUTPUT_DEFAULT})`,
    `  --registro  codici segnaletiche scritti dall'import (default: ${REGISTRO_DEFAULT})`
  ];
  console.log(uso.join('\n'));
}

function parseArgomenti(argv) {
  const opzioni = { input: CSV_DEFAULT, output: OUTPUT_DEFAULT, registro: REGISTRO_DEFAULT };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--input' && argv[i + 1]) {
      opzioni.input = argv[++i];
    } else if (argv[i] === '--output' && argv[i + 1]) {
      opzioni.output = argv[++i];
    } else if (argv[i] === '--registro' && argv[i + 1]) {
      opzioni.registro = argv[++i];
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

// Registro dei codici scritto dall'import delle foto segnaletiche: righe
// nome;cognome;squadriglia;codice con intestazione, solo appensione. Qui è
// in sola lettura.
function parseRegistroContenuto(contenuto) {
  const records = parse(contenuto, {
    delimiter: SEPARATORE,
    bom: true,
    skip_empty_lines: true,
    from_line: 2 // la prima riga è l'intestazione scritta dall'import
  });
  return records
    .map((campi) => ({
      nome: String(campi[0] == null ? '' : campi[0]).trim(),
      cognome: String(campi[1] == null ? '' : campi[1]).trim(),
      squadriglia: String(campi[2] == null ? '' : campi[2]).trim(),
      codice: String(campi[3] == null ? '' : campi[3]).trim()
    }))
    .filter((r) => r.nome !== '' || r.cognome !== '' || r.codice !== '');
}

// Restituisce null se il file non esiste: è la valvola di sicurezza (import
// mai lanciato -> comportamento precedente invariato).
function leggiRegistro(percorso) {
  if (!fs.existsSync(percorso)) {
    return null;
  }
  return parseRegistroContenuto(fs.readFileSync(percorso, 'utf8'));
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
  const registro = leggiRegistro(opzioni.registro || REGISTRO_DEFAULT);
  const anonimo = process.env.ANONIMO === '1';

  console.error(`anagrafica: letti ${csv.righe.length} ragazzi da ${opzioni.input}${anonimo ? ' (modalità anonima)' : ''}`);
  if (registro === null) {
    // valvola di sicurezza: senza import le chiavi restano nomecognome
    console.error(`anagrafica: registro segnaletiche non trovato (${opzioni.registro || REGISTRO_DEFAULT}): chiavi legacy nomecognome`);
  } else {
    console.error(`anagrafica: lette ${registro.length} righe di codici da ${opzioni.registro || REGISTRO_DEFAULT}`);
  }

  const squadriglie = generaSquadriglie(csv.righe, { anonimo, registro });

  // Righe di registro senza corrispondenza nel CSV: tipico ragazzo spostato
  // di squadriglia direttamente nel CSV, o riga da correggere a mano nel
  // registro (vedi Readme §3). Non fatale: il codice resta però senza member.
  if (registro !== null) {
    const chiaviCsv = new Set(
      csv.righe.map((r) => chiaveIdentita(r.nome, r.cognome, r.squadriglia))
    );
    for (const r of registro) {
      if (!chiaviCsv.has(chiaveIdentita(r.nome, r.cognome, r.squadriglia))) {
        console.error(`anagrafica: warning: il codice '${r.codice}' (${r.nome} ${r.cognome}, sq. ${r.squadriglia}) non trova nessun ragazzo nel CSV: correggi la riga nel registro o l'export`);
      }
    }
  }

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

// Campo d'identità in forma ASCII minuscola senza spazi né apostrofi:
// stesso criterio dell'idRagazzo e della normalizzazione dell'import bash,
// così "Dell'Orto" nel CSV matcha "dellorto" nel filename del registro.
function asciiCampo(testo) {
  return transliterate(String(testo == null ? '' : testo).trim(), { trim: false })
    .toLowerCase()
    .replace(/['’]/g, '')
    .replace(/\s+/g, '');
}

// Chiave di incrocio CSV <-> registro per nome+cognome+squadriglia.
function chiaveIdentita(nome, cognome, squadriglia) {
  return `${asciiCampo(nome)}|${asciiCampo(cognome)}|${asciiCampo(squadriglia)}`;
}

// Iniziali puntate per la griglia anonima ("M. R." da mario rossi): prima
// lettera maiuscola del nome e della prima parola del cognome, ognuna col
// punto. Campi mancanti -> stringa vuota senza errori: una voce senza
// dicitura e' meglio di una build fallita la sera del campo. E' l'UNICO
// frammento d'identita' che entra nel json anonimo (mai il nome completo).
function inizialiPuntate(nome, cognome) {
  const iniziale = (s) => {
    const c = String(s == null ? '' : s).trim().charAt(0);
    return c ? `${c.toUpperCase()}.` : '';
  };
  const primoCognome = String(cognome == null ? '' : cognome).trim().split(/\s+/)[0];
  return [iniziale(nome), iniziale(primoCognome)].filter(Boolean).join(' ');
}

// Costruisce le squadriglie dalle righe del CSV.
// - reale: members con tutti i campi, chiavi per codice dell'import se il
//   ragazzo è nel registro, altrimenti id legacy nomecognome;
// - anonima: i soli codici dei ragazzi con foto importata
//   ({codice: {ini: "M. R."}}, change iniziali-squadriglieri-anonimi),
//   members vuoti senza registro.
// L'ordine è quello di prima apparizione nel CSV (oggi dava l'elenco
// hardcoded "per anzianità" del vecchio PHP).
function generaSquadriglie(righe, opzioni) {
  const anonimo = !!(opzioni && opzioni.anonimo);
  const registro = Array.isArray(opzioni && opzioni.registro) ? opzioni.registro : null;
  // ponte sulle identità: chiave normalizzata -> codice assegnato all'import
  const mappaCodici = new Map();
  if (registro !== null) {
    for (const r of registro) {
      mappaCodici.set(chiaveIdentita(r.nome, r.cognome, r.squadriglia), r.codice);
    }
  }
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
    const codice = registro === null
      ? undefined
      : mappaCodici.get(chiaveIdentita(
        String(riga.nome || ''), String(riga.cognome || ''), riga.squadriglia));
    if (anonimo) {
      // solo chi ha una foto importata compare in griglia: codice + iniziali
      // puntate (nessun altro dato anagrafico)
      if (codice) {
        squadriglie[squadriglia].members[codice] = { ini: inizialiPuntate(riga.nome, riga.cognome) };
      }
      continue;
    }
    const ragazzo = {};
    for (const [chiave, valore] of Object.entries(riga)) {
      ragazzo[chiave] = String(valore == null ? '' : valore).toLowerCase();
    }
    ragazzo.nome = maiuscolizza(ragazzo.nome);
    ragazzo.cognome = maiuscolizza(ragazzo.cognome);
    // chiave del member: il codice dell'import se c'è la foto, altrimenti
    // l'id da nome+cognome come sempre (valvola: registro assente o ragazzo
    // senza foto segnaletica)
    const id = codice || idRagazzo(ragazzo.nome, ragazzo.cognome);
    squadriglie[squadriglia].members[id] = ragazzo;
  }
  return squadriglie;
}

module.exports = {
  normalizzaChiave,
  leggiCsv,
  parseRegistroContenuto,
  leggiRegistro,
  validaIntestazione,
  chiaveIdentita,
  maiuscolizza,
  idRagazzo,
  generaSquadriglie
};

if (require.main === module) {
  main();
}
