'use strict';

// Test di coerenza link -> pagina per l'angolo squadriglie (change
// anagrafica-node-anonima): il filename della pagina ragazzo è la chiave
// del member (id ASCII calcolato da genera_anagrafica), così il link
// {{@key}}.html nella pagina della squadriglia porta sempre alla pagina
// giusta, cognomi accentati compresi.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

function copiaIsolata() {
  // build() scrive in <__dirname>/src: si lavora su una copia in tmp per
  // non toccare i sorgenti generati della repo
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'angolisq-test-'));
  fs.mkdirSync(path.join(tmp, 'template'));
  fs.copyFileSync(path.join(__dirname, 'index.js'), path.join(tmp, 'index.js'));
  for (const f of fs.readdirSync(path.join(__dirname, 'template'))) {
    const p = path.join(__dirname, 'template', f);
    if (fs.statSync(p).isFile()) {
      fs.copyFileSync(p, path.join(tmp, 'template', f));
    }
  }
  return tmp;
}

test('pagina ragazzo: il filename è la chiave del member (id ASCII), cognome accentato compreso', () => {
  const tmp = copiaIsolata();
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const logger = { info() {}, warn() {}, error() {} };
    const squadriglie = {
      oro: {
        name: 'oro',
        members: {
          ginevrapero: { nome: 'Ginevra', cognome: 'Però', dtnascita: '11/02/2008' },
          chiaradellorto: { nome: 'Chiara', cognome: "Dell'Orto", dtnascita: '03/09/2007' }
        }
      }
    };
    new Angolisq(logger, squadriglie, []).build();

    const files = fs.readdirSync(path.join(tmp, 'src')).sort();
    assert.ok(files.includes('ginevrapero.hbs'),
      `la pagina deve chiamarsi ginevrapero.hbs (trovato: ${files.join(', ')})`);
    assert.ok(files.includes('chiaradellorto.hbs'),
      `la pagina deve chiamarsi chiaradellorto.hbs (trovato: ${files.join(', ')})`);
    assert.equal(files.filter((f) => /[àèéìòù]/.test(f)).length, 0,
      'nessuna pagina con accenti nel filename (il link {{@key}}.html non la troverebbe)');

    // la pagina ragazzo usa l'id come nome file e nei link alle foto:
    // nessun placeholder lasciato a metà
    const pagina = fs.readFileSync(path.join(tmp, 'src', 'ginevrapero.hbs'), 'utf8');
    assert.match(pagina, /ginevrapero/);
    assert.doesNotMatch(pagina, /##/);

    // la pagina della squadriglia linka i member con la chiave:
    // link e pagina devono coincidere per costruzione
    const sq = fs.readFileSync(path.join(tmp, 'src', 'oro.hbs'), 'utf8');
    assert.match(sq, /\{\{#each squadriglie\.oro\.members\}\}/);
    assert.match(sq, /\{\{@key\}\}\.html/);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('pagina squadriglia: members vuoti (modalità anonima) -> nessuna pagina ragazzo', () => {
  const tmp = copiaIsolata();
  try {
    const Angolisq = require(path.join(tmp, 'index.js'));
    const logger = { info() {}, warn() {}, error() {} };
    const squadriglie = {
      oro: { name: 'oro', members: {} },
      blu: { name: 'blu', members: {} }
    };
    new Angolisq(logger, squadriglie, []).build();

    const files = fs.readdirSync(path.join(tmp, 'src')).sort();
    assert.deepEqual(files, ['blu.hbs', 'index.hbs', 'oro.hbs'],
      'solo le pagine squadriglia: foto/urlo/hike restano, nessuna scheda ragazzo');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
