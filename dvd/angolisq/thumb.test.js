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
    const istanza = {
      // registra le geometrie richieste: serve ai test sul fotogruppo
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

test('fotogruppo: thumb larga 650 rigenerata, non quella piccola del batch', async () => {
  const resizeChiamate = [];
  const ripristina = gmDisponibile ? null : installaStubGm({ resizeChiamate });
  const vecchia = Buffer.from('thumb vecchia del fotogruppo, da sostituire');
  const tmp = copiaIsolata({
    'materiale/reparto/fotogruppo.jpg': JPEG_1X1,
    // simula il disco con una thumb rimasta da una build precedente
    'materiale/reparto/thumb_fotogruppo.jpg': vecchia,
    'materiale/reparto/mr1_blu.jpg': JPEG_1X1
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    await new Angolisq(loggerMuto(),
      { blu: { name: 'blu', members: { mr1_blu: { ini: 'M. R.' } } } }, []).build();

    const thumb = fs.readFileSync(path.join(tmp, 'materiale/reparto/thumb_fotogruppo.jpg'));
    assert.notDeepEqual(thumb, vecchia,
      'la thumb del fotogruppo va rigenerata anche se esiste gia\'');
    assert.ok(fs.existsSync(path.join(tmp, 'materiale/reparto/thumb_mr1_blu.jpg')),
      'il batch da 150 continua a occuparsi dei codici ragazzi');
    if (!gmDisponibile) {
      // con lo stub possiamo vedere la geometria richiesta
      const larga = resizeChiamate.find((args) => args[0] === 650);
      assert.ok(larga, 'il fotogruppo deve passare da resize(650)');
      assert.equal(larga.length, 1, 'resize a sola larghezza: altezza in proporzione');
    }
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('urli dinamici: tutti i file <sq>.<ext> e <sq>_N.<ext> finiscono sul json della pagina', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({
    'materiale/urli/oro.mp3': 'urlo uno',
    'materiale/urli/oro_2.wav': 'urlo due',
    'materiale/urli/blu.avi': 'urlo blu',
    // non deve comparire: nome fuori pattern per oro
    'materiale/urli/verde.mp3': 'altra sq'
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const squadriglie = {
      oro: { name: 'oro', members: {} },
      blu: { name: 'blu', members: {} }
    };
    const materiale = [{
      title: 'Urli Squadriglia', dir: 'urli',
      per_squadriglia: ['avi', 'mp3', 'wav'], responsabile: ['Riccardo']
    }];
    await new Angolisq(loggerMuto(), squadriglie, materiale).build();

    assert.deepEqual(squadriglie.oro.urli, [
      { nome: 'oro.mp3', testo: 'Urlo di Sq.' },
      { nome: 'oro_2.wav', testo: 'Urlo di Sq. 2' }
    ]);
    assert.deepEqual(squadriglie.blu.urli, [{ nome: 'blu.avi', testo: 'Urlo di Sq.' }]);
  } finally {
    if (ripristina) ripristina();
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('scheda anonima: dalla griglia si raggiunge la pagina del ragazzo con la foto intera', async () => {
  const ripristina = gmDisponibile ? null : installaStubGm();
  const tmp = copiaIsolata({
    'materiale/reparto/ca1_blu.jpg': JPEG_1X1
  });
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const squadriglie = { blu: { name: 'blu', members: { ca1_blu: { ini: 'C. A.' } } } };
    await new Angolisq(loggerMuto(), squadriglie, []).build();

    // la build genera la pagina individuale ANONIMA dal template dedicato
    const scheda = path.join(tmp, 'src', 'ca1_blu.hbs');
    assert.ok(fs.existsSync(scheda), 'deve esistere la scheda anonima del ragazzo');
    const contenuto = fs.readFileSync(scheda, 'utf8');
    assert.match(contenuto, /reparto\/ca1_blu\.jpg/, 'link alla foto intera');
    assert.match(contenuto, /thumb_ca1_blu\.jpg/, 'thumb come anteprima');
    assert.match(contenuto, /blu\.html/, 'ritorno alla squadriglia');

    // il member porta l'annotazione per la griglia-link di sq.hbs
    assert.equal(squadriglie.blu.members.ca1_blu.fotointera, 'ca1_blu.jpg');
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
