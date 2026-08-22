#!/usr/bin/env node
'use strict';

// Golden build: snapshot/confronto dell'output della build per verificare
// meccanicamente che un cambio di toolchain produca lo stesso sito
// (change aggiornamento-dipendenze, spec verifica-regressione-build).
//
//   node scripts/golden.js salva     <dir-build> <file-manifest> [--escludi prefisso ...]
//   node scripts/golden.js confronta <dir-build> <file-manifest>
//
// Solo moduli built-in: niente dipendenze nuove da aggiungere proprio
// quando si stanno misurando le dipendenze. Il manifest dichiara le sue
// regole (esclusioni e immagini presence-only) cosi' il confronto usa le
// stesse regole dello snapshot. Tool ausiliario: NON e' nel percorso di
// `make build`, non modifica l'output del sito.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Estensioni delle immagini raster generate/copiate: una patch di
// ImageMagick puo' cambiare i byte JPEG a parita' di immagine, quindi si
// confronta solo la presenza, non l'hash (design D5).
const ESTENSIONI_PRESENCE_ONLY = ['.jpg', '.jpeg', '.png', '.gif'];

// Quante segnalazioni mostrare nel report prima di riassumere il resto:
// il report deve stare su una schermata.
const LIMITE_ELENCO = 40;

// ----------------------------------------------------------------- utilità

function usage(canale) {
  canale.write([
    'Uso: golden.js <modalità> <dir-build> <file-manifest> [--escludi prefisso ...]',
    '',
    '  salva     salva lo snapshot dell\'output corrente nel manifest',
    '  confronta confronta l\'output attuale con l\'ultimo snapshot salvato',
    '',
    'Esempio: make golden-salva / make golden-confronta'
  ].join('\n') + '\n');
}

function scriviJsonAtomico(percorso, oggetto) {
  const tmp = percorso + '.tmp';
  fs.mkdirSync(path.dirname(percorso), { recursive: true });
  fs.writeFileSync(tmp, JSON.stringify(oggetto, null, 2) + '\n');
  fs.renameSync(tmp, percorso);
}

function sha256File(pieno) {
  return crypto.createHash('sha256').update(fs.readFileSync(pieno)).digest('hex');
}

function eImmagine(relativo) {
  const est = path.extname(relativo).toLowerCase();
  return ESTENSIONI_PRESENCE_ONLY.includes(est);
}

function eEscluso(relativo, esclusioni) {
  return esclusioni.some(prefisso =>
    relativo === prefisso || relativo.startsWith(prefisso));
}

// Percorsi relativi con slash del sito (non del SO), ordinati
function percorsiRelativi(dirBase) {
  const risultati = [];
  const visita = (dir) => {
    for (const voce of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const pieno = path.join(dir, voce.name);
      if (voce.isDirectory()) {
        visita(pieno);
      } else if (voce.isFile()) {
        risultati.push(path.relative(dirBase, pieno).split(path.sep).join('/'));
      }
    }
  };
  visita(dirBase);
  return risultati;
}

// ------------------------------------------------------------- modalità

function creaManifest(dirBuild, esclusioni) {
  const manifest = {
    tool: 'golden build — snapshot dell\'output della build',
    salvato_il: new Date().toISOString(),
    regole: {
      // elenco esplicito nel manifest stesso: al confronta valgono queste,
      // non opzioni passate a mano (design D5)
      esclusioni: esclusioni.slice().sort(),
      presence_only: ESTENSIONI_PRESENCE_ONLY.slice()
    },
    file: {}
  };

  for (const relativo of percorsiRelativi(dirBuild)) {
    if (eEscluso(relativo, manifest.regole.esclusioni)) continue;
    const pieno = path.join(dirBuild, relativo);
    if (eImmagine(relativo)) {
      manifest.file[relativo] = { presence: true };
    } else {
      manifest.file[relativo] = {
        hash: sha256File(pieno),
        dimensione: fs.statSync(pieno).size
      };
    }
  }
  return manifest;
}

function confrontaManifest(dirBuild, manifest) {
  const esclusioni = manifest.regole.esclusioni || [];
  const attuali = new Set();
  const differenze = [];

  for (const relativo of percorsiRelativi(dirBuild)) {
    if (eEscluso(relativo, esclusioni)) continue;
    attuali.add(relativo);

    const atteso = manifest.file[relativo];
    if (!atteso) {
      differenze.push({ tipo: 'INATTESO', file: relativo });
      continue;
    }
    if (atteso.presence) {
      continue; // immagine: basta che ci sia (già verificato dall'esistenza)
    }
    if (sha256File(path.join(dirBuild, relativo)) !== atteso.hash) {
      differenze.push({ tipo: 'DIVERGENTE', file: relativo });
    }
  }

  for (const relativo of Object.keys(manifest.file)) {
    if (!attuali.has(relativo)) {
      differenze.push({ tipo: 'MANCANTE', file: relativo });
    }
  }

  return differenze.sort((a, b) => a.file.localeCompare(b.file) || a.tipo.localeCompare(b.tipo));
}

// ------------------------------------------------------------------ main

function main(argv) {
  const [modo, dirBuildArg, manifestArg] = argv;

  if (!modo || !dirBuildArg || !manifestArg ||
      !['salva', 'confronta'].includes(modo)) {
    usage(process.stderr);
    process.stderr.write('Errore: modalità o argomenti mancanti/sbagliati.\n');
    return 2;
  }

  // --escludi prefisso ... (ripetibile): solo in fase di salva, poi le
  // regole vivono nel manifest
  const esclusioni = [];
  for (let i = 3; i < argv.length; i++) {
    if (argv[i] === '--escludi' && argv[i + 1]) {
      let prefisso = argv[++i].split(path.sep).join('/');
      if (!prefisso.endsWith('/')) prefisso += '/';
      esclusioni.push(prefisso);
    }
  }

  const dirBuild = path.resolve(dirBuildArg);
  const percorsoManifest = path.resolve(manifestArg);

  // la directory build deve esistere ed essere plausibile: una directory
  // vuota non è una build (index.html deve esserci)
  if (!fs.existsSync(path.join(dirBuild, 'index.html'))) {
    process.stderr.write(
      'Errore: in "' + dirBuildArg + '" non c\'è una build completata (manca index.html).\n' +
      'Lancia prima "make build", poi riprova.\n');
    return 1;
  }

  if (modo === 'salva') {
    scriviJsonAtomico(percorsoManifest, creaManifest(dirBuild, esclusioni));
    const quanti = Object.keys(JSON.parse(fs.readFileSync(percorsoManifest, 'utf8')).file).length;
    process.stdout.write(
      'golden build — snapshot salvato in ' + manifestArg + '\n' +
      '  file registrati: ' + quanti + ' (immagini ' +
      ESTENSIONI_PRESENCE_ONLY.join(' ') + ' presence-only)\n' +
      'Prossimo passo dopo la prossima build: make golden-confronta\n');
    return 0;
  }

  if (!fs.existsSync(percorsoManifest)) {
    process.stderr.write(
      'Errore: nessuno snapshot in "' + manifestArg + '".\n' +
      'Lancia prima "make golden-salva" su una build di riferimento.\n');
    return 1;
  }

  const manifest = JSON.parse(fs.readFileSync(percorsoManifest, 'utf8'));
  const differenze = confrontaManifest(dirBuild, manifest);
  const totali = Object.keys(manifest.file).length;

  if (differenze.length === 0) {
    process.stdout.write(
      'golden build — confronto con lo snapshot del ' + manifest.salvato_il + '\n' +
      '  file identici: ' + totali + ' → l\'output coincide con lo snapshot.\n');
    return 0;
  }

  process.stdout.write(
    'golden build — confronto con lo snapshot del ' + manifest.salvato_il + '\n' +
    '  file nello snapshot: ' + totali + ', differenze: ' + differenze.length + '\n' +
    'DIVERGENZE:\n');
  for (const d of differenze.slice(0, LIMITE_ELENCO)) {
    process.stdout.write('  ' + d.tipo.padEnd(11) + ' ' + d.file + '\n');
  }
  if (differenze.length > LIMITE_ELENCO) {
    process.stdout.write('  … e altre ' + (differenze.length - LIMITE_ELENCO) + ' differenze\n');
  }
  process.stdout.write(
    'Confronto FALLITO: l\'output non coincide con lo snapshot.\n' +
    'Se la differenza è attesa (cambio reale di contenuto), rigenera lo snapshot con "make golden-salva".\n');
  return 1;
}

if (require.main === module) {
  process.exit(main(process.argv.slice(2)));
}

module.exports = { creaManifest, confrontaManifest, ESTENSIONI_PRESENCE_ONLY };
