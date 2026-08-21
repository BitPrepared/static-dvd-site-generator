'use strict';

// Test della generazione thumb del diario fotografico (change
// fix-thumb-logger), gemello di dvd/angolisq/thumb.test.js: la build non
// termina prima che i thumb siano su disco e un fallimento riporta
// l'errore reale con il file coinvolto.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const JPEG_1X1 = Buffer.from(
  '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////' +
  '////////////////////////////////////////////////////////////////2wBDAf/' +
  '//////////////////////////////////////////////////////////////////////' +
  '////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBE' +
  'BAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAA' +
  'gBAwEBPwF//9k=',
  'base64'
);
const IMMAGINE_CORROTTA = Buffer.from(
  '89504e470d0a1a0a0000000048494e4f2121212121',
  'hex'
);

const gmDisponibile = spawnSync('convert', ['-version']).status === 0;

function installaStubGm(opzioni) {
  const originale = require('gm');
  const percorsoGm = require.resolve('gm');
  function fintoGm(buffer) {
    return {
      resize() { return this; },
      write(destinazione, cb) {
        setImmediate(() => {
          if (opzioni && opzioni.erroreSu && destinazione.match(opzioni.erroreSu)) {
            cb(new Error('gm convert: corrupted image'));
            return;
          }
          fs.writeFileSync(destinazione, buffer);
          cb(null);
        });
      }
    };
  }
  fintoGm.subClass = () => fintoGm;
  require.cache[percorsoGm].exports = fintoGm;
  return () => { require.cache[percorsoGm].exports = originale; };
}

function copiaIsolata(foto) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'diario-thumb-'));
  fs.mkdirSync(path.join(tmp, 'template'));
  fs.copyFileSync(path.join(__dirname, 'index.js'), path.join(tmp, 'index.js'));
  for (const f of fs.readdirSync(path.join(__dirname, 'template'))) {
    const p = path.join(__dirname, 'template', f);
    if (fs.statSync(p).isFile()) {
      fs.copyFileSync(p, path.join(tmp, 'template', f));
    }
  }
  for (const [relativo, contenuto] of Object.entries(foto)) {
    const destino = path.join(tmp, 'materiale/foto', relativo);
    fs.mkdirSync(path.dirname(destino), { recursive: true });
    fs.writeFileSync(destino, contenuto);
  }
  return tmp;
}

const ESTENSIONI = ['jpg', 'jpeg', 'png', 'gif'];
const CATEGORIE = ['giorno1'];

test('build attende i thumb: alla fine della build i thumb sono su disco (una sola build basta)', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({
    'giorno1/foto1.jpg': JPEG_1X1,
    'giorno1/foto2.jpg': JPEG_1X1
  });
  try {
    const DiarioFotografico = require(path.join(tmp, 'index.js'));
    await new DiarioFotografico({ info() {}, warn() {}, error() {} }, ESTENSIONI, CATEGORIE).build();

    for (const atteso of [
      'materiale/thumb/giorno1/foto1.jpg',
      'materiale/thumb/giorno1/foto2.jpg'
    ]) {
      assert.ok(fs.existsSync(path.join(tmp, atteso)),
        `dopo build() il thumb deve essere su disco: ${atteso}`);
    }
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('immagine corrotta: la build fallisce con errore reale + file, senza crash su logger', async () => {
  const ripristina = gmDisponibile
    ? null
    : installaStubGm({ erroreSu: /thumb\/giorno1\/corrotta\.jpg$/ });
  const tmp = copiaIsolata({
    'giorno1/foto1.jpg': JPEG_1X1,
    'giorno1/corrotta.jpg': IMMAGINE_CORROTTA
  });
  try {
    const DiarioFotografico = require(path.join(tmp, 'index.js'));
    await assert.rejects(
      () => new DiarioFotografico({ info() {}, warn() {}, error() {} }, ESTENSIONI, CATEGORIE).build(),
      (err) => {
        assert.match(err.message, /corrotta\.jpg/, 'il messaggio deve nominare il file');
        assert.doesNotMatch(err.message, /logger|undefined/);
        return true;
      }
    );
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
