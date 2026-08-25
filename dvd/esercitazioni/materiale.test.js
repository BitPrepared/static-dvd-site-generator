'use strict';

// Test del check materiale delle esercitazioni: le voci con nomi file fissi
// vengono verificate una per una; le cartelle libere ("qualcosa ci deve
// essere", change messaggi-missing) vengono riempite con cio' che contengono
// e segnalate solo se vuote o assenti.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

// Copia del plugin in una dir isolata: il check legge <dir>/materiale
function copiaIsolata(materiale) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'esercitazioni-'));
  fs.copyFileSync(path.join(__dirname, 'index.js'), path.join(tmp, 'index.js'));
  for (const [relativo, contenuto] of Object.entries(materiale)) {
    const destino = path.join(tmp, relativo);
    fs.mkdirSync(path.dirname(destino), { recursive: true });
    fs.writeFileSync(destino, contenuto);
  }
  return tmp;
}

function loggerMuto() {
  return { info() {}, warn() {}, error() {}, success() {} };
}

test('cartella_libera: i file presenti finiscono in files[], la cartella piena non e\' missing', () => {
  const tmp = copiaIsolata({
    'materiale/multimediale/presentazione.odp': 'sorgente',
    'materiale/multimediale/REV02.pdf': 'pdf nuovo'
  });
  try {
    const Esercitazioni = require(path.join(tmp, 'index.js'));
    const sezione = new Esercitazioni(loggerMuto(), [{
      title: 'Multimediale', dir: 'multimediale', cartella_libera: true,
      responsabile: ['Riccardo']
    }], []);
    const missing = sezione.check();

    assert.equal(missing.length, 0, 'cartella piena: nessun missing');
    // files[] riempito col contenuto reale, ordinato: il template linka questi
    assert.deepEqual(sezione.materiale[0].files.map((f) => f.filename),
      ['REV02.pdf', 'presentazione.odp']);
    // etichetta leggibile: niente estensione, underscore -> spazi
    assert.deepEqual(sezione.materiale[0].files.map((f) => f.description),
      ['REV02', 'presentazione']);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('cartella_libera: cartella vuota o assente -> un solo missing con suggerimento', () => {
  const tmp = copiaIsolata({});
  fs.mkdirSync(path.join(tmp, 'materiale/multimediale'), { recursive: true });
  try {
    const Esercitazioni = require(path.join(tmp, 'index.js'));
    const descrittore = {
      title: 'Multimediale', dir: 'multimediale', cartella_libera: true,
      responsabile: ['Riccardo']
    };
    const missingVuota = new Esercitazioni(loggerMuto(), [descrittore], []).check();

    assert.equal(missingVuota.length, 1);
    assert.match(missingVuota[0].title, /vuota/);
    assert.match(missingVuota[0].suggerimento || '', /qualunque nome/i);

    // cartella del tutto assente: missing sulla cartella, non sui singoli file
    const assente = new Esercitazioni(loggerMuto(), [{
      title: 'Multimediale', dir: 'inesistente', cartella_libera: true,
      responsabile: ['Riccardo']
    }], []).check();
    assert.equal(assente.length, 1);
    assert.match(assente[0].attesoIn, /materiale\/inesistente\/$/);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('voci con nomi fissi: i file mancanti continuano a essere segnalati uno per uno', () => {
  const tmp = copiaIsolata({
    'materiale/app/app.pdf': 'c\'e solo il pdf'
  });
  try {
    const Esercitazioni = require(path.join(tmp, 'index.js'));
    const missing = new Esercitazioni(loggerMuto(), [{
      title: 'App', dir: 'app', responsabile: ['Nicola'],
      files: [
        { filename: 'app.pdf', description: 'Il pdf' },
        { filename: 'app.sorgente.zip', description: 'Il sorgente' }
      ]
    }], []).check();

    assert.equal(missing.length, 1, 'manca solo il sorgente');
    assert.equal(missing[0].filename, 'app.sorgente.zip');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
