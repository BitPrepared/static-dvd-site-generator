'use strict';

// Test del tool di golden build (node --test scripts/test_golden.js).
// Solo moduli built-in come lo script sotto test: le fixture stanno in
// directory temporanee, ogni scenario lancia il comando come processo
// separato per verificare exit code e report (stile genera_anagrafica.test.js).

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');

const SCRIPT = path.join(__dirname, 'golden.js');

function tmpDir(prefisso) {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefisso));
}

function lancia(args) {
  return spawnSync(process.execPath, [SCRIPT].concat(args), { encoding: 'utf8' });
}

function scrivi(base, relativo, contenuto) {
  const pieno = path.join(base, relativo);
  fs.mkdirSync(path.dirname(pieno), { recursive: true });
  fs.writeFileSync(pieno, contenuto);
}

function sha256(contenuto) {
  return crypto.createHash('sha256').update(contenuto).digest('hex');
}

// Fixture realistica: una pagina, un css, una foto raster, un documento
function preparaBuild(dir) {
  scrivi(dir, 'index.html', '<html>HOME</html>\n');
  scrivi(dir, 'css/stile.css', 'body{color:white}\n');
  scrivi(dir, 'img/footer.png', Buffer.from([0x89, 0x50, 0x4e, 0x47, 1, 2, 3]));
  scrivi(dir, 'esercitazioni/prbmm/index.html', '<html>PRBMM</html>\n');
}

test('salva: manifest scritto con percorsi relativi e hash SHA-256', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    const manifestPath = path.join(golden, 'manifest.json');
    const esito = lancia(['salva', build, manifestPath]);

    assert.equal(esito.status, 0, esito.stderr);
    assert.ok(fs.existsSync(manifestPath), 'il manifest deve essere scritto');

    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    const file = manifest.file;

    // chiavi = percorsi relativi con gli slash del sito, non dell'OS
    assert.deepEqual(Object.keys(file).sort(), [
      'css/stile.css',
      'esercitazioni/prbmm/index.html',
      'img/footer.png',
      'index.html'
    ]);

    // testo: hash SHA-256 del contenuto + dimensione
    assert.equal(file['index.html'].hash, sha256('<html>HOME</html>\n'));
    assert.equal(file['index.html'].dimensione, Buffer.byteLength('<html>HOME</html>\n'));

    // immagine raster: presence-only, niente hash da confrontare
    assert.equal(file['img/footer.png'].presence, true);
    assert.equal(file['img/footer.png'].hash, undefined);

    // le regole (esclusioni/presence-only) sono dichiarate nel manifest stesso
    assert.deepEqual(manifest.regole.presence_only, ['.jpg', '.jpeg', '.png', '.gif']);
    assert.ok(Array.isArray(manifest.regole.esclusioni));
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('confronta: output identico -> exit 0', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    const manifestPath = path.join(golden, 'manifest.json');

    assert.equal(lancia(['salva', build, manifestPath]).status, 0);
    const esito = lancia(['confronta', build, manifestPath]);
    assert.equal(esito.status, 0, 'output identico deve passare: ' + esito.stdout + esito.stderr);
    assert.match(esito.stdout, /ident/i);
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('confronta: file divergente -> exit != 0 con report che lo nomina', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    const manifestPath = path.join(golden, 'manifest.json');
    lancia(['salva', build, manifestPath]);

    scrivi(build, 'index.html', '<html>HOME MODIFICATA</html>\n');
    const esito = lancia(['confronta', build, manifestPath]);

    assert.notEqual(esito.status, 0);
    assert.match(esito.stdout + esito.stderr, /divergente/i);
    assert.match(esito.stdout + esito.stderr, /index\.html/);
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('confronta: file inatteso -> exit != 0 con report che lo nomina', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    const manifestPath = path.join(golden, 'manifest.json');
    lancia(['salva', build, manifestPath]);

    scrivi(build, 'varie/nuovo.html', '<html>NUOVO</html>\n');
    const esito = lancia(['confronta', build, manifestPath]);

    assert.notEqual(esito.status, 0);
    assert.match(esito.stdout + esito.stderr, /inatteso/i);
    assert.match(esito.stdout + esito.stderr, /varie\/nuovo\.html/);
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('confronta: file mancante -> exit != 0 con report che lo nomina', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    const manifestPath = path.join(golden, 'manifest.json');
    lancia(['salva', build, manifestPath]);

    fs.rmSync(path.join(build, 'img', 'footer.png'));
    const esito = lancia(['confronta', build, manifestPath]);

    assert.notEqual(esito.status, 0);
    assert.match(esito.stdout + esito.stderr, /mancante/i);
    assert.match(esito.stdout + esito.stderr, /img\/footer\.png/);
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('confronta: immagine modificata a pari presenza -> exit 0 (presence-only)', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    const manifestPath = path.join(golden, 'manifest.json');
    lancia(['salva', build, manifestPath]);

    // stessa immagine "rigenerata" con byte diversi: come una patch IM6
    scrivi(build, 'img/footer.png', Buffer.from([0x89, 0x50, 0x4e, 0x47, 9, 9, 9]));
    const esito = lancia(['confronta', build, manifestPath]);

    assert.equal(esito.status, 0, 'le immagini si confrontano presence-only');
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('esclusioni: i percorsi esclusi dallo snapshot non diventano inattesi', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    scrivi(build, 'tmp/volatile.txt', 'cambia sempre\n');
    const manifestPath = path.join(golden, 'manifest.json');

    const esitoSalva = lancia(['salva', build, manifestPath, '--escludi', 'tmp/']);
    assert.equal(esitoSalva.status, 0, esitoSalva.stderr);
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    assert.deepEqual(manifest.regole.esclusioni, ['tmp/']);
    assert.equal(manifest.file['tmp/volatile.txt'], undefined);

    // al confronto il file volatile e' cambiato ma resta escluso
    scrivi(build, 'tmp/volatile.txt', 'contenuto diverso\n');
    const esito = lancia(['confronta', build, manifestPath]);
    assert.equal(esito.status, 0, 'gli esclusi non devono produrre segnalazioni');
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('diagnostica: confronta senza snapshot -> exit != 0, suggerisce golden-salva', () => {
  const build = tmpDir('golden-build-');
  const golden = tmpDir('golden-snap-');
  try {
    preparaBuild(build);
    const esito = lancia(['confronta', build, path.join(golden, 'manifest.json')]);

    assert.notEqual(esito.status, 0);
    assert.match(esito.stdout + esito.stderr, /golden-salva/);
  } finally {
    fs.rmSync(build, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('diagnostica: salva senza build valida -> exit != 0, suggerisce make build', () => {
  const buildVuota = tmpDir('golden-vuoto-');
  const golden = tmpDir('golden-snap-');
  try {
    const esito = lancia(['salva', buildVuota, path.join(golden, 'manifest.json')]);

    assert.notEqual(esito.status, 0, 'una directory vuota non e\' una build');
    assert.match(esito.stdout + esito.stderr, /make build/);
    assert.equal(fs.existsSync(path.join(golden, 'manifest.json')), false,
      'nessun manifest parziale scritto');

    const esitoAssente = lancia(['salva', path.join(buildVuota, 'inesistente'),
      path.join(golden, 'manifest.json')]);
    assert.notEqual(esitoAssente.status, 0);
  } finally {
    fs.rmSync(buildVuota, { recursive: true, force: true });
    fs.rmSync(golden, { recursive: true, force: true });
  }
});

test('diagnostica: modalità o argomenti sbagliati -> usage in italiano, exit != 0', () => {
  const esitoModo = lancia(['scatta', 'build', 'golden/manifest.json']);
  assert.notEqual(esitoModo.status, 0);
  assert.match(esitoModo.stdout + esitoModo.stderr, /salva|confronta/);

  const esitoArgs = lancia(['salva']);
  assert.notEqual(esitoArgs.status, 0);
});
