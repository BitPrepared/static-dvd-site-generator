'use strict';

// Test della griglia codici e della pubblicita' selettiva delle thumb
// (change foto-segnaletiche-codificate): la pagina squadriglia mostra una
// griglia di foto segnaletiche per i member SENZA campo nome (modalita'
// codice/anonima), le pagine individuali nascono solo dai member con nome,
// e in reparto/ viene pubblicato solo cio' che il json riconosce.
//
// Stessa tecnica di thumb.test.js: copia isolata del plugin e gm sostituito
// da uno stub se ImageMagick non c'e'.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

// JPEG 1x1 valido
const JPEG_1X1 = Buffer.from(
  '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////' +
  '////////////////////////////////////////////////////////////////2wBDAf/' +
  '//////////////////////////////////////////////////////////////////////' +
  '////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBE' +
  'BAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAA' +
  'gBAwEBPwF//9k=',
  'base64'
);

const gmDisponibile = spawnSync('convert', ['-version']).status === 0;

function installaStubGm() {
  const originale = require('gm');
  const percorsoGm = require.resolve('gm');
  function fintoGm(buffer) {
    return {
      resize() { return this; },
      write(destinazione, cb) {
        setImmediate(() => { fs.writeFileSync(destinazione, buffer); cb(null); });
      }
    };
  }
  fintoGm.subClass = () => fintoGm;
  require.cache[percorsoGm].exports = fintoGm;
  return () => { require.cache[percorsoGm].exports = originale; };
}

function copiaIsolata(materiale) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'angolisq-griglia-'));
  fs.mkdirSync(path.join(tmp, 'template'));
  fs.copyFileSync(path.join(__dirname, 'index.js'), path.join(tmp, 'index.js'));
  for (const f of fs.readdirSync(path.join(__dirname, 'template'))) {
    const p = path.join(__dirname, 'template', f);
    if (fs.statSync(p).isFile()) fs.copyFileSync(p, path.join(tmp, 'template', f));
  }
  for (const [relativo, contenuto] of Object.entries(materiale)) {
    const destino = path.join(tmp, relativo);
    fs.mkdirSync(path.dirname(destino), { recursive: true });
    fs.writeFileSync(destino, contenuto);
  }
  return tmp;
}

function loggerRaccoglitore() {
  const avvisi = [];
  return {
    warn: (msg) => avvisi.push(String(msg)),
    info() {}, error() {}, success() {},
    avvisi
  };
}

// json anonimo: soli codici, member senza campo nome (fixture
// dati/squadriglie.example-anonima.json). La pagina squadriglia scritta da
// build() e' un template handlebars: la griglia itera {{this.fotosegn}}
// che la build annota sui member; il rendering avviene nel generatore.
test('griglia (anonima): niente pagine individuali, member annotati col proprio thumb', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({
    'materiale/reparto/pz1_oro.jpg': JPEG_1X1,
    'materiale/reparto/gp1_oro.png': JPEG_1X1
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const logger = loggerRaccoglitore();
    const squadriglie = {
      oro: { name: 'oro', members: { pz1_oro: {}, gp1_oro: {} } }
    };
    await new Angolisq(logger, squadriglie, []).build();

    const src = fs.readdirSync(path.join(tmp, 'src')).sort();
    assert.ok(src.includes('oro.hbs'), 'la pagina della squadriglia esiste');
    assert.ok(!src.includes('pz1_oro.hbs') && !src.includes('gp1_oro.hbs'),
      'nessuna pagina individuale per i soli codici');

    // annotazioni per la griglia: estensione vera per ogni codice
    assert.equal(squadriglie.oro.members.pz1_oro.hafoto, true);
    assert.equal(squadriglie.oro.members.pz1_oro.fotosegn, 'thumb_pz1_oro.jpg');
    assert.equal(squadriglie.oro.members.gp1_oro.fotosegn, 'thumb_gp1_oro.png',
      'l\'estensione segue il file importato');

    const sq = fs.readFileSync(path.join(tmp, 'src', 'oro.hbs'), 'utf8');
    assert.match(sq, /\{\{#each squadriglie\.oro\.members\}\}/,
      'la griglia itera i member');
    assert.match(sq, /\{\{#if this\.nome\}\}<li><a href="\{\{@key\}\}\.html">/,
      'chi ha il nome resta un link di testo');
    assert.match(sq, /angolisq\/reparto\/\{\{this\.fotosegn\}\}/,
      'il ramo senza nome punta al thumb annotato');
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// modalità reale: member con nome -> pagina individuale col codice nell'URL
test('reale: member con nome -> pagina <codice>.hbs; senza foto -> build comunque ok', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({
    // solo Pippo ha la foto, Maria no
    'materiale/reparto/pz1_oro.jpg': JPEG_1X1
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const squadriglie = {
      oro: {
        name: 'oro',
        members: {
          pz1_oro: { nome: 'Pippo', cognome: 'Zoo', dtnascita: '24/07/2007' },
          mb1_oro: { nome: 'Maria Luigia', cognome: 'Bianchi', dtnascita: '01/01/2007' }
        }
      }
    };
    await new Angolisq(loggerRaccoglitore(), squadriglie, []).build();

    const src = fs.readdirSync(path.join(tmp, 'src')).sort();
    assert.ok(src.includes('pz1_oro.hbs'), 'pagina del ragazzo con foto');
    assert.ok(src.includes('mb1_oro.hbs'),
      'pagina anche per chi non ha foto: il member ha il nome, la scheda esiste');
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// pubblicità selettiva: file estraneo in reparto/ -> warning, nessun thumb
test('pubblicita\' selettiva: file estraneo in reparto/ segnalato e fuori dal sito', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({
    'materiale/reparto/pz1_oro.jpg': JPEG_1X1,
    // vecchio sample col nome vero nel filename
    'materiale/reparto/AlessandroPiazza.JPG': JPEG_1X1
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const logger = loggerRaccoglitore();
    const squadriglie = { oro: { name: 'oro', members: { pz1_oro: {} } } };
    const plugin = new Angolisq(logger, squadriglie, []);
    await plugin.build();

    const reparto = path.join(tmp, 'materiale', 'reparto');
    assert.ok(fs.existsSync(path.join(reparto, 'thumb_pz1_oro.jpg')),
      'il thumb del codice noto viene generato');
    assert.ok(!fs.existsSync(path.join(reparto, 'thumb_AlessandroPiazza.JPG')),
      'nessun thumb per il file estraneo');

    const pubblicabili = plugin.filePubblicabiliReparto();
    assert.ok(!pubblicabili.has('AlessandroPiazza.JPG'),
      'il file estraneo non e\' pubblicabile');
    assert.ok(pubblicabili.has('pz1_oro.jpg') && pubblicabili.has('thumb_pz1_oro.jpg'),
      'i file del codice noto sono pubblicabili');

    assert.ok(logger.avvisi.some((a) => a.includes('AlessandroPiazza.JPG')),
      'warning di build che nomina il file non riconosciuto');
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// griglia senza foto: codice nel json ma foto mai importata -> fuori griglia
test('anonima: codice senza foto assente dalla griglia, senza errori', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({}); // reparto vuota
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const squadriglie = { oro: { name: 'oro', members: { pz1_oro: {} } } };
    await new Angolisq(loggerRaccoglitore(), squadriglie, []).build();

    const sq = fs.readFileSync(path.join(tmp, 'src', 'oro.hbs'), 'utf8');
    assert.doesNotMatch(sq, /thumb_pz1_oro/, 'senza foto il codice non finisce in griglia');
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
