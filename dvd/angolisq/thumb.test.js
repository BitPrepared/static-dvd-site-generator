'use strict';

// Test della generazione thumb dell'angolo squadriglie (change
// fix-thumb-logger): la build della sezione non termina prima che i thumb
// siano su disco e un fallimento riporta l'errore reale con il file
// coinvolto (niente più crash su this.logger).
//
// Se il binario ImageMagick non c'è (fuori container), gm viene sostituito
// da uno stub: nel container (make bash) gli stessi test girano con gm vero.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

// JPEG 1x1 valido (per fixture che gm vero sappia leggere)
const JPEG_1X1 = Buffer.from(
  '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////' +
  '////////////////////////////////////////////////////////////////2wBDAf/' +
  '//////////////////////////////////////////////////////////////////////' +
  '////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBE' +
  'BAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAA' +
  'gBAwEBPwF//9k=',
  'base64'
);
// byte PNG su un file .jpg: per gm è un'immagine corrotta
const IMMAGINE_CORROTTA = Buffer.from(
  '89504e470d0a1a0a0000000048494e4f2121212121',
  'hex'
);

const gmDisponibile = spawnSync('convert', ['-version']).status === 0;

// Sostituisce gm con un finto convert asincrono; restituisce la funzione
// per ripristinare il modulo originale.
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

// Copia del plugin in una dir isolata (build() scrive in <dir>/src e
// <dir>/materiale) con il materiale di test.
function copiaIsolata(materiale) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'angolisq-thumb-'));
  fs.mkdirSync(path.join(tmp, 'template'));
  fs.copyFileSync(path.join(__dirname, 'index.js'), path.join(tmp, 'index.js'));
  for (const f of fs.readdirSync(path.join(__dirname, 'template'))) {
    const p = path.join(__dirname, 'template', f);
    if (fs.statSync(p).isFile()) {
      fs.copyFileSync(p, path.join(tmp, 'template', f));
    }
  }
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

test('build attende i thumb: alla fine della build i thumb sono su disco (una sola build basta)', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({
    'materiale/guidoni/g1.jpg': JPEG_1X1,
    'materiale/guidoni/g2.jpg': JPEG_1X1,
    'materiale/squadriglia/oro.jpg': JPEG_1X1,
    'materiale/reparto/fotogruppo.jpg': JPEG_1X1
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    await new Angolisq(loggerMuto(), { oro: { name: 'oro', members: {} } }, []).build();

    for (const atteso of [
      'materiale/guidoni/thumb_g1.jpg',
      'materiale/guidoni/thumb_g2.jpg',
      'materiale/squadriglia/thumb_oro.jpg',
      'materiale/reparto/thumb_fotogruppo.jpg'
    ]) {
      assert.ok(fs.existsSync(path.join(tmp, atteso)),
        `dopo build() il thumb deve essere su disco: ${atteso}`);
    }
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('thumb già presenti non vengono rigenerati', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const esistente = Buffer.from('thumb vecchia, da non toccare');
  const tmp = copiaIsolata({
    'materiale/guidoni/g1.jpg': JPEG_1X1,
    'materiale/guidoni/thumb_g1.jpg': esistente
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    await new Angolisq(loggerMuto(), { oro: { name: 'oro', members: {} } }, []).build();

    assert.deepEqual(
      fs.readFileSync(path.join(tmp, 'materiale/guidoni/thumb_g1.jpg')),
      esistente,
      'il thumb esistente non va sovrascritto'
    );
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('immagine corrotta: la build fallisce con errore reale + file, senza crash su logger', async () => {
  const ripristina = gmDisponibile
    ? null
    : installaStubGm({ erroreSu: /thumb_corrotta\.jpg$/ });
  const tmp = copiaIsolata({
    'materiale/guidoni/g1.jpg': JPEG_1X1,
    'materiale/guidoni/corrotta.jpg': IMMAGINE_CORROTTA
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    await assert.rejects(
      () => new Angolisq(loggerMuto(), { oro: { name: 'oro', members: {} } }, []).build(),
      (err) => {
        assert.match(err.message, /corrotta\.jpg/, 'il messaggio deve nominare il file');
        assert.match(err.message, /corrupt|unable|error|ENOENT|gm/i,
          'e riportare l\'errore reale della libreria immagini');
        assert.doesNotMatch(err.message, /logger|undefined/,
          'non un crash indiretto su riferimenti interni');
        return true;
      }
    );
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
