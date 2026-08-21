#!/usr/bin/env node
// Genera il footer del sito (build/img/footer.png) dal template SVG + date
// del campo. Change OpenSpec: footer-dinamico-da-svg (ricetta e requisiti lì).
//
// Uso:
//   node scripts/genera_footer.js ["gg-gg/mm/aaaa"] [--config dati/campo.json]
//        [--out file.png] [--font file.ttf] [--fallback file.png]
//
// Senza argomenti legge le date da dati/campo.json, che le tiene separate
// ({"inizio": "gg/mm/aaaa", "fine": "gg/mm/aaaa"}); per il template vengono
// ricomposte nel formato compatto gg-gg/mm/aaaa. La build lo invoca così
// (make build); make footer DATE=... è la variante manuale di prova.
// A ogni generazione riuscita aggiorna la risorsa scripts/footer_fallback.png
// (usata dalla build se la generazione fallisce).

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const TEMPLATE = path.join(__dirname, 'footer_template.svg');
const FONT_DEFAULT = path.join(__dirname, 'star_jedi', 'Starjout.ttf');
const OUT_DEFAULT = path.join(ROOT, 'build', 'img', 'footer.png');
const FALLBACK_DEFAULT = path.join(__dirname, 'footer_fallback.png');
const CONFIG_DEFAULT = path.join(ROOT, 'dati', 'campo.json');
const FONT_FAMILY = 'Star Jedi Outline';

// Self-check del bbox dell'inchiostro (alpha > 128), tolleranze della spec:
// l'originale 2023 ha inchiostro da (180,8) a (751,38), larghezza 572.
// La larghezza dipende dalle cifre delle date ma resta in un intervallo
// stretto: fuori da qui = segnaposto non sostituito o testo corrotto.
const BBOX = { left: [179, 181], top: [7, 9], bottom: [36, 40], width: [540, 620] };

function esci(msg) {
  console.error('');
  console.error(msg);
  console.error('');
  process.exit(1);
}

// Log nello stile della pipeline (lib/logger.js):
//   [ INFO ] --- Footer @ generazione ---
//   [ INFO ] footer generata: ...
// chalk e' gia' una dipendenza del generatore; se manca si logga senza colori.
let chalk = null;
try {
  // eslint-disable-next-line global-require
  chalk = require('chalk');
} catch (e) {
  chalk = null;
}
function logInfo(msg, modulo) {
  const w = (s) => (chalk ? chalk.white(s) : s);
  const b = (s) => (chalk ? chalk.blue(s) : s);
  const c = (s) => (chalk ? chalk.cyan(s) : s);
  const riga = modulo
    ? w('[ ') + b('INFO') + w(' ] --- ') + msg + ' @ ' + c(modulo) + w(' --- ')
    : w('[ ') + b('INFO') + w(' ] ') + msg;
  process.stderr.write(riga + '\n');
}

function uso() {
  return [
    'Uso: node scripts/genera_footer.js ["gg-gg/mm/aaaa"] [--config dati/campo.json] [--out file.png] [--font file.ttf]',
    'Esempio: node scripts/genera_footer.js "22-26/08/2023"',
    '         node scripts/genera_footer.js --config dati/campo.json'
  ].join('\n');
}

function validaDate(s) {
  const m = /^(\d{2})-(\d{2})\/(\d{2})\/(\d{4})$/.exec(s);
  if (!m) return 'Formato date non valido: atteso gg-gg/mm/aaaa (es. 22-26/08/2023)';
  const [, gs1, gs2, ms] = m;
  if (gs1 < '01' || gs1 > '31' || gs2 < '01' || gs2 > '31') {
    return 'Giorni fuori range (01-31): ' + s;
  }
  if (ms < '01' || ms > '12') {
    return 'Mese fuori range (01-12): ' + s;
  }
  if (gs2 < gs1) {
    return 'La data di fine precede quella di inizio: ' + s;
  }
  return null;
}

// data singola "gg/mm/aaaa" (campo di dati/campo.json): null se valida
function validaDataSingola(etichetta, s) {
  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(s);
  if (!m) return 'Formato ' + etichetta + ' non valido: atteso gg/mm/aaaa (es. 22/08/2023)';
  const [, g, ms] = m;
  if (g < '01' || g > '31') {
    return 'Giorno di ' + etichetta + ' fuori range (01-31): ' + s;
  }
  if (ms < '01' || ms > '12') {
    return 'Mese di ' + etichetta + ' fuori range (01-12): ' + s;
  }
  return null;
}

// Ricompone le due date separate nel formato compatto gg-gg/mm/aaaa del
// template: la ricetta tipografica ha canvas a larghezza fissa e un solo
// mese/anno, quindi un campo a cavallo di mesi diversi non è rappresentabile.
function componeDate(inizio, fine) {
  const errore = validaDataSingola('inizio', inizio) || validaDataSingola('fine', fine);
  if (errore) esci(errore);
  const [, g1, ms1, aa1] = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(inizio);
  const [, g2, ms2, aa2] = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(fine);
  if (ms1 !== ms2 || aa1 !== aa2) {
    esci('Le date del campo sono a cavallo di mesi/anni (' + inizio + ' -> ' + fine +
      '): il footer supporta un solo mese/anno.');
  }
  if (g2 < g1) {
    esci('La data di fine precede quella di inizio: ' + inizio + ' -> ' + fine);
  }
  return g1 + '-' + g2 + '/' + ms1 + '/' + aa1;
}

// --- argomenti ---
const argv = process.argv.slice(2);
let date = null;
let out = OUT_DEFAULT;
let font = FONT_DEFAULT;
let config = null;
let fallback = undefined; // undefined = decide lo script (vedi sotto)
for (let i = 0; i < argv.length; i++) {
  if (argv[i] === '--out') out = argv[++i];
  else if (argv[i] === '--font') font = argv[++i];
  else if (argv[i] === '--fallback') fallback = argv[++i];
  else if (argv[i] === '--config') config = argv[++i];
  else if (argv[i] === '--help' || argv[i] === '-h') esci(uso());
  else date = argv[i];
}
if (date && config) {
  esci('Data passata due volte, insieme come argomento e in --config: scegline una.');
}
if (!date && !config) {
  // senza argomenti si prova il dato di struttura standard
  if (fs.existsSync(CONFIG_DEFAULT)) config = CONFIG_DEFAULT;
  else esci('Date del campo mancanti (argomento o dati/campo.json).\n' + uso());
}
if (config) {
  if (!fs.existsSync(config)) {
    esci('Config assente: ' + config + '\nDato di struttura atteso: dati/campo.json (git checkout / git pull).');
  }
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(config, 'utf8'));
  } catch (e) {
    esci('Config non leggibile come JSON: ' + config +
      '\nAtteso il formato di dati/campo.json, es. {"inizio": "22/08/2023", "fine": "26/08/2023"}\n' + e.message);
  }
  if (typeof parsed.inizio !== 'string' || !parsed.inizio ||
      typeof parsed.fine !== 'string' || !parsed.fine) {
    esci('Config senza campi "inizio"/"fine": ' + config +
      '\nAtteso es. {"inizio": "22/08/2023", "fine": "26/08/2023"}');
  }
  date = componeDate(parsed.inizio, parsed.fine);
}

const errore = validaDate(date);
if (errore) esci(errore);

// --- prerequisiti ---
if (!fs.existsSync(TEMPLATE)) {
  esci('Template assente: ' + TEMPLATE + '\nIl file viaggia in git: git checkout / git pull.');
}
if (!fs.existsSync(font)) {
  esci(
    'Font assente: ' + font +
    '\nScaricalo con: make font (download da www.dafont.com/star-jedi.font, estratti solo i .ttf)'
  );
}

let Resvg;
try {
  // eslint-disable-next-line global-require
  Resvg = require('@resvg/resvg-js').Resvg;
} catch (e) {
  esci(
    'Dipendenza @resvg/resvg-js non disponibile (node_modules del generatore).\n' +
    'Ricostruisci l\'immagine con: make init'
  );
}

// --- render ---
const svg = fs.readFileSync(TEMPLATE, 'utf8').replaceAll('{{DATE}}', date);
const resvg = new Resvg(svg, {
  font: {
    fontFiles: [font],
    loadSystemFonts: false,
    defaultFontFamily: FONT_FAMILY
  },
  fitTo: { mode: 'width', value: 760 }
});

let rendered;
try {
  rendered = resvg.render();
} catch (e) {
  esci('Render fallito: ' + e.message);
}

// --- self-check bbox dai pixel (spec: ricetta tipografica) ---
const { width, height, pixels } = rendered;
let left = -1, top = -1, right = -1, bottom = -1;
for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) {
    if (pixels[(y * width + x) * 4 + 3] > 128) {
      if (left < 0 || x < left) left = x;
      if (top < 0 || y < top) top = y;
      if (x > right) right = x;
      if (y > bottom) bottom = y;
    }
  }
}
if (left < 0) {
  esci('Render vuoto: nessun pixel visibile (font caricato correttamente?)');
}
const fuori = (v, [min, max]) => v < min || v > max;
if (fuori(left, BBOX.left) || fuori(top, BBOX.top) || fuori(bottom, BBOX.bottom) ||
    fuori(right - left + 1, BBOX.width)) {
  esci(
    'Self-check fallito: bbox inchiostro (' + left + ',' + top + ')-(' + right + ',' + bottom + ')' +
    ' (larghezza ' + (right - left + 1) + ')' +
    ' fuori tolleranza (atteso left 180±1, top 8±1, bottom 37-39, larghezza ' +
    BBOX.width.join('-') + ').' +
    '\nQualcosa è cambiato nel font o nel renderer: verifica la ricetta in scripts/footer_template.svg'
  );
}

// --- scrittura atomica (mai PNG parziale al posto di una valida) ---
const png = rendered.asPng();
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out + '.tmp', png);
fs.renameSync(out + '.tmp', out);

// --- riserva (fallback): aggiornata con l'ultima buona generazione ---
// Regola: percorso esplicito con --fallback; altrimenti solo quando si
// scrive sull'output di default della build (le run di prova con --out
// personalizzato non inquinano la riserva).
const percorsoFallback =
  fallback !== undefined ? fallback
  : path.resolve(out) === path.resolve(OUT_DEFAULT) ? FALLBACK_DEFAULT
  : null;
if (percorsoFallback) {
  fs.mkdirSync(path.dirname(percorsoFallback), { recursive: true });
  fs.writeFileSync(percorsoFallback, png);
}

logInfo('Footer', 'generazione');
logInfo(
  'footer generata: ' + out +
  ' (date ' + date + ', inchiostro ' + (right - left + 1) + 'x' + (bottom - top + 1) +
  ' px da (' + left + ',' + top + ') a (' + right + ',' + bottom + '))' +
  (percorsoFallback ? ' [risorsa aggiornata: ' + percorsoFallback + ']' : '')
);
