'use strict';

// Test dello script di generazione dell'anagrafica (node --test anagrafica/).
// Le dipendenze (csv-parse, transliteration) arrivano dall'immagine del
// generatore (make init); fuori container passarle con NODE_PATH.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const genera = require('./genera_anagrafica.js');

const SCRIPT = path.join(__dirname, 'genera_anagrafica.js');

// Stessa intestazione del CSV reale (21 colonne, virgolettate, separatore ;)
const INTESTAZIONE = [
  '"Codicecensimento"', '"Nome"', '"Cognome"', '"Sesso"', '"Specialita"',
  '"SquadrigliaOrigine"', '"Reparto"', '"Gruppo"', '"Zona"', '"Via"',
  '"Ncivico"', '"CAP"', '"Citta"', '"Provincia"', '"Regione"',
  '"Squadriglia"', '"Ruolo"', '"Dt Nascita"', '"Telefono"', '"Email"',
  '"Instagram"'
].join(';');

// Riga di esempio coerente con dati/squadriglie.example.json (Pippo Zoo)
const RIGA_PIPPO = [
  '"001"', '"Pippo"', '"Zoo"', '"M"', '"fotografo"', '"Tigri"', '"Topos"',
  '"Topolinia 1"', '"Reggio Emilia"', '"Del basso"', '"81"', '"42019"',
  '"Topolinia"', '"Reggio Emilia"', '"veneto"', '"ORO"', '""',
  '"24/07/2007"', '"12345678901"', '"pippo@topolinia.it"', '""'
].join(';');

const RIGA_GINEVRA = [
  '"002"', '"Ginevra"', '"Però"', '"F"', '"artista"', '"Aquile"', '"Topos"',
  '"Topolinia 1"', '"Reggio Emilia"', '"Alta"', '"12"', '"42019"',
  '"Topolinia"', '"Reggio Emilia"', '"veneto"', '"ORO"', '""',
  '"11/02/2008"', '"0231234567"', '"ginevra@topolinia.it"', '""'
].join(';');

const RIGA_CHIARA = [
  '"003"', '"Chiara"', '"Dell\'Orto"', '"F"', '""', '"Tigri"', '"Topos"',
  '"Topolinia 1"', '"Reggio Emilia"', '"Bassa"', '"7"', '"42019"',
  '"Topolinia"', '"Reggio Emilia"', '"veneto"', '"BLU"', '""',
  '"03/09/2007"', '"0231234568"', '"chiara@topolinia.it"', '""'
].join(';');

// Riga di un quarto ragazzo finto, SENza foto segnaletica: non compare nel
// registro dell'import
const RIGA_MARIA = [
  '"004"', '"Maria Luigia"', '"Bianchi"', '"F"', '""', '"Aquile"', '"Topos"',
  '"Topolinia 1"', '"Reggio Emilia"', '"Alta"', '"9"', '"42019"',
  '"Topolinia"', '"Reggio Emilia"', '"veneto"', '"ORO"', '""',
  '"01/01/2007"', '""', '"maria@topolinia.it"', '""'
].join(';');

// Registro prodotto dall'import per i ragazzi finti dell'example
// (change foto-segnaletiche-codificate)
const REGISTRO_FINTO = [
  'nome;cognome;squadriglia;codice',
  'pippo;zoo;oro;pz1_oro',
  'ginevra;pero;oro;gp1_oro',
  'chiara;dellorto;blu;cd1_blu',
  ''
].join('\n');

function scriviRegistro(tmp, contenuto) {
  fs.writeFileSync(path.join(tmp, 'anagrafica', 'registro_segnaletiche.csv'), contenuto);
}

function tmpDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'anagrafica-test-'));
}

// Lancia lo script come processo separato (per exit code, stdout e stderr)
function lanciaScript(args, opzioni) {
  return spawnSync(process.execPath, [SCRIPT].concat(args), {
    cwd: opzioni.cwd,
    env: Object.assign({}, process.env, {
      ANONIMO: opzioni.anonimo ? '1' : '',
      NODE_PATH: process.env.NODE_PATH
    }),
    encoding: 'utf8'
  });
}

// ---------------------------------------------------------------- 1.2 parsing

test('parsing: separatore ;, intestazione normalizzata, campi quoted', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n';
  const risultato = genera.leggiCsv(csv);

  assert.deepEqual(
    risultato.intestazione.slice(0, 5),
    ['codicecensimento', 'nome', 'cognome', 'sesso', 'specialita']
  );
  assert.ok(risultato.intestazione.includes('dtnascita'), '"Dt Nascita" -> dtnascita');
  assert.equal(risultato.righe.length, 1);

  const riga = risultato.righe[0];
  // i campi quoted perdono le virgolette
  assert.equal(riga.nome, 'Pippo');
  assert.equal(riga.squadriglia, 'ORO');
  assert.equal(riga.dtnascita, '24/07/2007');
});

test('parsing: righe vuote tollerate (inizio, mezzo, fondo)', () => {
  const csv = '\n' + INTESTAZIONE + '\n\n' + RIGA_PIPPO + '\n\n';
  const risultato = genera.leggiCsv(csv);

  assert.equal(risultato.righe.length, 1);
  assert.equal(risultato.righe[0].cognome, 'Zoo');
});

// ---------------------------------------------------- 1.6 modalità anonima

test('anonima (unit): solo name e members vuoti, squadriglie dal CSV', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_CHIARA + '\n';
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe, { anonimo: true });

  assert.deepEqual(Object.keys(squadriglie), ['oro', 'blu']);
  assert.deepEqual(squadriglie.oro, { name: 'oro', members: {} });
  assert.deepEqual(squadriglie.blu, { name: 'blu', members: {} });
});

test('anonima (e2e): ANONIMO=1 -> json senza alcun valore anagrafico del CSV', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_GINEVRA + '\n' + RIGA_CHIARA + '\n');
    const esito = lanciaScript([], { cwd: tmp, anonimo: true });
    const scritto = fs.readFileSync(path.join(tmp, 'dati', 'squadriglie.json'), 'utf8');

    assert.equal(esito.status, 0, 'deve riuscire: ' + esito.stderr);
    // nessun dato ragazzo nel file: nomi, contatti, date, indirizzi...
    for (const valore of ['Pippo', 'pippo', 'Zoo', 'Ginevra', 'Però', 'Chiara',
      'Dell', '24/07/2007', 'pippo@topolinia.it', '12345678901', 'Del basso',
      'Topolinia 1', 'fotografo', 'artista']) {
      assert.ok(!scritto.includes(valore), `il json anonimo non deve contenere '${valore}'`);
    }
    assert.deepEqual(JSON.parse(scritto), {
      oro: { name: 'oro', members: {} },
      blu: { name: 'blu', members: {} }
    });
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// ------------------------------- 1.6bis modalità anonima col registro (ini)

test('anonima con registro: riga senza nome/cognome -> ini vuota, non errore', () => {
  const csvSenzaNome = INTESTAZIONE + '\n'
    + '"005";"";"";"F";"";"";"Topos";"";"";"";"";"";"";"";"";"BLU";"";"";"";"";""\n';
  const registro = genera.parseRegistroContenuto(
    'nome;cognome;squadriglia;codice\n;;blu;x1_blu\n');
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csvSenzaNome).righe, { anonimo: true, registro });

  assert.deepEqual(squadriglie.blu.members, { x1_blu: { ini: '' } });
});

// ------------------------------------------- 1.7 scrittura atomica e log

test('scrittura: json scritto, nessun .tmp residuo, log sul canale diagnostico', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_PIPPO + '\n');
    const esito = lanciaScript([], { cwd: tmp });
    const percorsoJson = path.join(tmp, 'dati', 'squadriglie.json');

    assert.equal(esito.status, 0, esito.stderr);
    assert.ok(fs.existsSync(percorsoJson), 'il json deve essere scritto');
    assert.equal(fs.existsSync(percorsoJson + '.tmp'), false, 'nessun .tmp residuo');
    // log diagnostici: come il Logger del generatore, su stderr (stdout resta pulito)
    assert.match(esito.stderr, /anagrafica:.*squadriglie\.json/);
    assert.deepEqual(JSON.parse(fs.readFileSync(percorsoJson, 'utf8')).oro.members.pippozoo.nome, 'Pippo');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('scrittura: --output esplicito rispettato', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_PIPPO + '\n');
    const esito = lanciaScript(['--output', 'fuori/custom.json'], { cwd: tmp });

    assert.equal(esito.status, 0, esito.stderr);
    assert.ok(fs.existsSync(path.join(tmp, 'fuori', 'custom.json')));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// ------------------------------------------------ 1.8 warning singleton

test('warning: squadriglia con un solo ragazzo -> avviso su stderr, ma esce 0', () => {
  const tmp = tmpDir();
  try {
    // Pippo e Ginevra in ORO, Chiara da sola in BLU: possibile typo nel CSV
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_GINEVRA + '\n' + RIGA_CHIARA + '\n');
    const esito = lanciaScript([], { cwd: tmp });

    assert.equal(esito.status, 0, 'il warning non è fatale');
    assert.match(esito.stderr, /warning.*blu.*un solo ragazzo/s);
    assert.doesNotMatch(esito.stderr, /warning.*oro/s);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// -------------------------------------------------- 1.4/1.5 generazione reale

test('generazione reale: squadriglie dai valori distinti in ordine di prima apparizione', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_GINEVRA + '\n' + RIGA_CHIARA + '\n';
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe, { anonimo: false });

  // BLU appare dopo ORO nel CSV: l'ordine segue la prima apparizione,
  // non un elenco fisso nello script
  assert.deepEqual(Object.keys(squadriglie), ['oro', 'blu']);
  assert.equal(squadriglie.oro.name, 'oro');
  assert.equal(squadriglie.oro.members.pippozoo.nome, 'Pippo');
});

test('generazione reale: members con tutti i campi del CSV, valori minuscoli, nome/cognome in maiuscoletto', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_GINEVRA + '\n';
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe, { anonimo: false });
  const ragazzo = squadriglie.oro.members.ginevrapero;

  assert.equal(ragazzo.codicecensimento, '002');
  assert.equal(ragazzo.sesso, 'f');
  assert.equal(ragazzo.regione, 'veneto');
  assert.equal(ragazzo.dtnascita, '11/02/2008');
  assert.equal(ragazzo.squadriglia, 'oro');
  // come il PHP: nome e cognome con iniziale maiuscola, resto minuscolo
  assert.equal(ragazzo.nome, 'Ginevra');
  assert.equal(ragazzo.cognome, 'Però');
});

test('id ragazzo: ASCII, minuscolo, senza spazi né apostrofi; la chiave del member È l\'id', () => {
  const csv = [
    INTESTAZIONE,
    RIGA_GINEVRA,                       // cognome accentato
    RIGA_CHIARA,                        // cognome con apostrofo
    // nome composto: "Maria Luigia Bianchi" (sq BLU)
    '"004";"Maria Luigia";"Bianchi";"F";"";"";"Topos";"Topolinia 1";"Reggio Emilia";"Nova";"3";"42019";"Topolinia";"Reggio Emilia";"veneto";"BLU";"";"01/01/2007";"";"";""'
  ].join('\n') + '\n';
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe, { anonimo: false });

  assert.deepEqual(
    Object.keys(squadriglie.oro.members),
    ['ginevrapero'],
    'cognome accentato: la chiave è la forma ASCII'
  );
  assert.deepEqual(
    Object.keys(squadriglie.blu.members).sort(),
    ['chiaradellorto', 'marialuigiabianchi'],
    'apostrofo rimosso, nome composto senza spazi'
  );
});



function preparaCsv(tmp, contenuto) {
  fs.mkdirSync(path.join(tmp, 'anagrafica'), { recursive: true });
  fs.mkdirSync(path.join(tmp, 'dati'), { recursive: true });
  if (contenuto !== null) {
    fs.writeFileSync(path.join(tmp, 'anagrafica', 'elenco_ragazzi.csv'), contenuto);
  }
}

// ------------------------------------- change foto-segnaletiche-codificate

test('registro (unit): members chiavi per codice, tutti i campi del CSV conservati', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_GINEVRA + '\n' + RIGA_CHIARA + '\n';
  const registro = genera.parseRegistroContenuto(REGISTRO_FINTO);
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe,
    { anonimo: false, registro });

  assert.deepEqual(
    Object.keys(squadriglie.oro.members),
    ['pz1_oro', 'gp1_oro'],
    'le chiavi sono i codici dell\'import, nell\'ordine del CSV'
  );
  assert.deepEqual(Object.keys(squadriglie.blu.members), ['cd1_blu']);

  const pippo = squadriglie.oro.members.pz1_oro;
  assert.equal(pippo.nome, 'Pippo');
  assert.equal(pippo.cognome, 'Zoo');
  assert.equal(pippo.dtnascita, '24/07/2007');
  assert.equal(pippo.email, 'pippo@topolinia.it');
  assert.equal(pippo.squadriglia, 'oro');
});

test('registro (unit): ragazzo nel CSV senza foto -> member senza codice (id legacy)', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_MARIA + '\n';
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe,
    { anonimo: false, registro: genera.parseRegistroContenuto(REGISTRO_FINTO) });

  assert.deepEqual(Object.keys(squadriglie.oro.members).sort(), ['marialuigiabianchi', 'pz1_oro'],
    'chi ha una foto usa il codice, chi non ce l\'ha resta sull\'identificativo nomecognome');
});

test('valvola (unit): registro assente -> chiavi legacy nomecognome, identico a oggi', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_GINEVRA + '\n' + RIGA_CHIARA + '\n';
  const conValvola = genera.generaSquadriglie(genera.leggiCsv(csv).righe,
    { anonimo: false, registro: null });

  // confronto con la generazione "storica" (nessun concetto di registro)
  const legacy = genera.generaSquadriglie(genera.leggiCsv(csv).righe, { anonimo: false });

  assert.deepEqual(conValvola, legacy);
  assert.deepEqual(Object.keys(conValvola.oro.members), ['pippozoo', 'ginevrapero']);
});

test('anonima (unit): col registro i members portano codice e iniziali puntate', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_GINEVRA + '\n'
    + RIGA_CHIARA + '\n' + RIGA_MARIA + '\n';
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe,
    { anonimo: true, registro: genera.parseRegistroContenuto(REGISTRO_FINTO) });

  // Maria non ha foto: in anonima non compare; gli altri codice + ini
  // (iniziale nome + prima parola del cognome: Dell'Orto -> D.)
  assert.deepEqual(squadriglie.oro, {
    name: 'oro',
    members: { pz1_oro: { ini: 'P. Z.' }, gp1_oro: { ini: 'G. P.' } }
  });
  assert.deepEqual(squadriglie.blu, { name: 'blu', members: { cd1_blu: { ini: 'C. D.' } } });
});

test('anonima (unit): senza registro members vuoti come nella pipeline precedente', () => {
  const csv = INTESTAZIONE + '\n' + RIGA_PIPPO + '\n';
  const squadriglie = genera.generaSquadriglie(genera.leggiCsv(csv).righe,
    { anonimo: true, registro: null });

  assert.deepEqual(squadriglie.oro, { name: 'oro', members: {} });
});

test('registro (e2e): json reale chiavi per codice; riga di registro fuori CSV -> warning, exit 0', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_PIPPO + '\n');
    // Ginevra nel registro ma non nel CSV: il warning deve nominarla
    scriviRegistro(tmp, REGISTRO_FINTO);
    const esito = lanciaScript([], { cwd: tmp });
    const scritto = JSON.parse(fs.readFileSync(path.join(tmp, 'dati', 'squadriglie.json'), 'utf8'));

    assert.equal(esito.status, 0, esito.stderr);
    assert.deepEqual(Object.keys(scritto.oro.members), ['pz1_oro']);
    assert.match(esito.stderr, /gp1_oro/, 'il warning nomina il codice senza corrispondenza');
    assert.match(esito.stderr, /ginevra/i, '...e anche l\'identita\'');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('registro (e2e): file assente -> valvola, json identico alle chiavi nomecognome', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_GINEVRA + '\n');
    const esito = lanciaScript([], { cwd: tmp });
    const scritto = JSON.parse(fs.readFileSync(path.join(tmp, 'dati', 'squadriglie.json'), 'utf8'));

    assert.equal(esito.status, 0, esito.stderr);
    assert.deepEqual(Object.keys(scritto.oro.members), ['ginevrapero']);
    assert.match(esito.stderr, /registro/i, 'diagnostica: dichiara che gira senza registro');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('anonima (e2e): ANONIMO=1 col registro -> soli codici, grep anti-dati sul json', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_PIPPO + '\n' + RIGA_GINEVRA + '\n' + RIGA_CHIARA + '\n');
    scriviRegistro(tmp, REGISTRO_FINTO);
    const esito = lanciaScript([], { cwd: tmp, anonimo: true });
    const scritto = fs.readFileSync(path.join(tmp, 'dati', 'squadriglie.json'), 'utf8');

    assert.equal(esito.status, 0, esito.stderr);
    for (const valore of ['Pippo', 'Zoo', 'Ginevra', 'Però', 'Chiara', 'Dell',
      'pippo@topolinia.it', '12345678901', 'Topolinia']) {
      assert.ok(!scritto.includes(valore), `il json anonimo non deve contenere '${valore}'`);
    }
    assert.deepEqual(JSON.parse(scritto), {
      oro: { name: 'oro', members: { pz1_oro: { ini: 'P. Z.' }, gp1_oro: { ini: 'G. P.' } } },
      blu: { name: 'blu', members: { cd1_blu: { ini: 'C. D.' } } }
    });
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('diagnostica: CSV assente -> exit != 0, messaggio con il file atteso, nessun json scritto', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, null);
    const esito = lanciaScript([], { cwd: tmp });

    assert.notEqual(esito.status, 0, 'deve fallire senza CSV');
    assert.match(esito.stderr, /elenco_ragazzi\.csv/);
    assert.match(esito.stderr, /anagrafica/);
    assert.doesNotMatch(esito.stderr, /^TypeError|^Error: /m, 'niente stack trace criptico');
    assert.equal(fs.existsSync(path.join(tmp, 'dati', 'squadriglie.json')), false,
      'nessun json parziale scritto');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('diagnostica: colonna obbligatoria mancante -> exit != 0, colonna indicata, nessun json', () => {
  const tmp = tmpDir();
  try {
    // intestazione senza la colonna Squadriglia
    const intestazioneSenzaSq = INTESTAZIONE
      .replace(';"Squadriglia";', ';"SquadrigliaX";');
    preparaCsv(tmp, intestazioneSenzaSq + '\n' + RIGA_PIPPO + '\n');
    const esito = lanciaScript([], { cwd: tmp });

    assert.notEqual(esito.status, 0);
    assert.match(esito.stderr, /squadriglia/);
    assert.equal(fs.existsSync(path.join(tmp, 'dati', 'squadriglie.json')), false);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('diagnostica: CSV illeggibile -> exit != 0 con errore chiaro', () => {
  const tmp = tmpDir();
  try {
    preparaCsv(tmp, INTESTAZIONE + '\n' + RIGA_PIPPO + '\n');
    fs.chmodSync(path.join(tmp, 'anagrafica', 'elenco_ragazzi.csv'), 0o000);
    const esito = lanciaScript([], { cwd: tmp });

    assert.notEqual(esito.status, 0);
    assert.match(esito.stderr, /leggere|leggibile|permessi/i);
    assert.equal(fs.existsSync(path.join(tmp, 'dati', 'squadriglie.json')), false);
  } finally {
    fs.chmodSync(path.join(tmp, 'anagrafica', 'elenco_ragazzi.csv'), 0o644);
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
