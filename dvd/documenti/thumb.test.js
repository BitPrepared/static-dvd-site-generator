'use strict';

// Test della generazione della thumb della foto staff (pagina
// documenti/staff): larghezza fissa 650 con altezza in proporzione, build
// che la aspetta e fallimento rumoroso — stesso modello di
// dvd/angolisq/thumb.test.js (change fix-thumb-logger).
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

function installaStubGm(opzioni) {
  const originale = require('gm');
  const percorsoGm = require.resolve('gm');
  function fintoGm(buffer) {
    const istanza = {
      resize(...args) {
        if (opzioni && opzioni.resizeChiamate) opzioni.resizeChiamate.push(args);
        return istanza;
      },
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
    return istanza;
  }
  fintoGm.subClass = () => fintoGm;
  require.cache[percorsoGm].exports = fintoGm;
  return () => { require.cache[percorsoGm].exports = originale; };
}

// Copia del plugin in una dir isolata (build() scrive in <dir>/materiale)
function copiaIsolata(materiale) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'documenti-thumb-'));
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

test('foto staff: thumb larga 650 rigenerata anche se esiste gia\'', async () => {
  const resizeChiamate = [];
  const ripristina = gmDisponibile ? null : installaStubGm({ resizeChiamate });
  const vecchia = Buffer.from('thumb vecchia della foto staff, da sostituire');
  const tmp = copiaIsolata({
    'materiale/staff/foto-staff.jpg': JPEG_1X1,
    'materiale/staff/thumb_foto-staff.jpg': vecchia
  });
  try {
    const DocumentiGenerali = require(path.join(tmp, 'index.js'));
    await new DocumentiGenerali(loggerMuto(), []).build();

    const thumb = fs.readFileSync(path.join(tmp, 'materiale/staff/thumb_foto-staff.jpg'));
    assert.notDeepEqual(thumb, vecchia,
      'la thumb della foto staff va rigenerata anche se esiste gia\'');
    if (!gmDisponibile) {
      const larga = resizeChiamate.find((args) => args[0] === 650);
      assert.ok(larga, 'la foto staff deve passare da resize(650)');
      assert.equal(larga.length, 1, 'resize a sola larghezza: altezza in proporzione');
    }
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('immagine corrotta: la build fallisce con errore reale + file', async () => {
  const ripristina = gmDisponibile
    ? null
    : installaStubGm({ erroreSu: /thumb_foto-staff\.jpg$/ });
  const tmp = copiaIsolata({
    'materiale/staff/foto-staff.jpg': IMMAGINE_CORROTTA
  });
  try {
    const DocumentiGenerali = require(path.join(tmp, 'index.js'));
    await assert.rejects(
      () => new DocumentiGenerali(loggerMuto(), []).build(),
      (err) => {
        assert.match(err.message, /foto-staff\.jpg/, 'il messaggio deve nominare il file');
        assert.match(err.message, /corrupt|unable|error|ENOENT|gm/i,
          'e riportare l\'errore reale della libreria immagini');
        return true;
      }
    );
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
