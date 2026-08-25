// Base file config
const Home = require('./dvd/home/index.js');
const Esercitazioni = require('./dvd/esercitazioni/index.js');
const Angolisq = require('./dvd/angolisq/index.js');
const Programmi = require('./dvd/programmi/index.js');
const DocumentiGenerali = require('./dvd/documenti/index.js');
const Varie = require('./dvd/varie/index.js');
const DiarioFotografico = require('./dvd/diariofotografico/index.js');
const Logger = require('./lib/logger.js');
const GeneratoreHTML = require('./lib/generatore.js');
const path = require('path');
const rimraf = require('rimraf');

require('fs-extra-debug')
const fs = require('fs-extra');

const shell = require('shelljs');

// Dati obbligatori: se uno manca (o non è leggibile) si esce subito con un
// messaggio azionabile, niente stack trace criptici con il campo in corso.
const DATI_OBBLIGATORI = [
  { chiave: 'materialeAngoliSq', file: 'materialeAngoliSq.json',
    aiuto: "Dato di struttura del repo: 'git pull' o controlla dati/materialeAngoliSq.json" },
  { chiave: 'materialeWorkshop', file: 'materialeWorkshop.json',
    aiuto: "Dato di struttura del repo: 'git pull' o controlla dati/materialeWorkshop.json" },
  { chiave: 'materialeDocumentiGenerali', file: 'materialeDocumentiGenerali.json',
    aiuto: "Dato di struttura del repo: 'git pull' o controlla dati/materialeDocumentiGenerali.json" },
  { chiave: 'materialeVarie', file: 'materialeVarie.json',
    aiuto: "Dato di struttura del repo: 'git pull' o controlla dati/materialeVarie.json" },
  { chiave: 'materialeAltreAttivita', file: 'materialeAltreAttivita.json',
    aiuto: "Dato di struttura del repo: 'git pull' o controlla dati/materialeAltreAttivita.json" },
  { chiave: 'squadriglie', file: 'squadriglie.json',
    aiuto: "Genera l'anagrafica con 'make anagrafica' (serve anagrafica/elenco_ragazzi.csv)\n" +
           "Hai gia' le foto segnaletiche? Prima 'make segnaletiche': scrive il registro\n" +
           "anagrafica/registro_segnaletiche.csv e l'anagrafica usa i codici come chiavi\n" +
           'Per un test rapido: cp dati/squadriglie.example.json dati/squadriglie.json' },
  { chiave: 'categories', file: 'categorieDiarioFotografico.json',
    aiuto: "Dato di struttura del repo: 'git pull' o controlla dati/categorieDiarioFotografico.json" }
];

function leggiDatiObbligatori(elenco) {
  const dati = {};
  for (const voce of elenco) {
    const percorsoCompleto = path.join(__dirname, 'dati', voce.file);
    if (!fs.existsSync(percorsoCompleto)) {
      console.error('');
      console.error('Dato obbligatorio mancante: dati/' + voce.file);
      console.error(voce.aiuto);
      console.error('');
      process.exit(1);
    }
    try {
      dati[voce.chiave] = fs.readJsonSync(percorsoCompleto, 'utf8');
    } catch (err) {
      console.error('');
      console.error('Dato obbligatorio non leggibile: dati/' + voce.file);
      console.error(err.message);
      console.error('');
      process.exit(1);
    }
  }
  return dati;
}

// build() delle sezioni con thumb è async: il flusso attende che i
// thumb siano su disco prima del rendering (change fix-thumb-logger)
// Messaggio "missing" completo: titolo + responsabile + DOVE mettere il
// materiale che manca (attesoIn e' repo-relative, lo calcolano le sezioni
// nei loro check). Senza attesoIn resta il messaggio di una volta.
function messaggioMissing(currentValue) {
  const titolo = currentValue.title || currentValue.description || '?';
  const responsabili = currentValue.responsabile
    ? ' Responsabile [' + currentValue.responsabile.join(',') + ']'
    : '';
  const dove = currentValue.attesoIn
    ? ' -> mettilo in ' + currentValue.attesoIn +
      (currentValue.suggerimento ? ' (' + currentValue.suggerimento + ')' : '')
    : '';
  return 'missing: ' + titolo + '!' + responsabili + dove;
}

async function main() {
  const { materialeAngoliSq, materialeWorkshop, materialeDocumentiGenerali, materialeVarie, materialeAltreAttivita, squadriglie, categories } = leggiDatiObbligatori(DATI_OBBLIGATORI);

  const authorizedExts = ['jpg', 'jpeg', 'svg', 'png', 'gif', 'JPG', 'JPEG', 'SVG', 'PNG', 'GIF'];

  var menu = [
    {
      'url': 'esercitazioni/index.html',
      'alt': 'Esercitazioni'
    },
    {
      'url': 'angolisq/index.html',
      'alt': 'Angoli di sq.'
    },
    {
      'url': 'diariofotografico/index.html',
      'alt': 'Diario fotografico'
    },
    {
      'url': 'documenti/index.html',
      'alt': 'Documenti generali'
    },
    {
      'url': 'programmi/index.html',
      'alt': 'Programmi ed utilità'
    },
    {
      'url': 'varie/index.html',
      'alt': 'Varie'
    }
  ];

  var logger = new Logger();

  var home = new Home(logger);
  const missingHome = home.check();
  missingHome.forEach((currentValue, index, arr) => {
    logger.warn(messaggioMissing(currentValue));
  });
  home.clean();
  home.build();

  var esercitazioni = new Esercitazioni(logger, materialeWorkshop, materialeAltreAttivita);
  const missing = esercitazioni.check();
  missing.forEach((currentValue, index, arr) => {
    logger.warn(messaggioMissing(currentValue));
  });

  var angolisq = new Angolisq(logger, squadriglie, materialeAngoliSq);
  const missingAngoli = angolisq.check();
  missingAngoli.forEach((currentValue, index, arr) => {
    logger.warn(messaggioMissing(currentValue));
  });
  angolisq.clean();
  await angolisq.build();

  var programmi = new Programmi(logger);
  angolisq.check();

  var documentiGenerali = new DocumentiGenerali(logger, materialeDocumentiGenerali);
  const missingDocumentiGenerali = documentiGenerali.check();
  missingDocumentiGenerali.forEach((currentValue, index, arr) => {
    logger.warn(messaggioMissing(currentValue));
  });
  await documentiGenerali.build();

  var varie = new Varie(logger, materialeVarie);
  const missingVarie = varie.check();
  missingVarie.forEach((currentValue, index, arr) => {
    logger.warn(messaggioMissing(currentValue));
  });

  var diariofotografico = new DiarioFotografico(logger, authorizedExts ,categories);
  const missingDiario = diariofotografico.check();
  missingDiario.forEach((currentValue, index, arr) => {
    logger.warn(messaggioMissing(currentValue));
  });

  diariofotografico.clean();
  await diariofotografico.build();

  const env_debug = ['true', '1', 'yes'].includes((process.env.DEBUG || '').toLowerCase());

  logger.info('PrepareResources', 'prepare config');

  const outputdir = path.join(__dirname, 'build');

  var config = {
    title: 'Bit Prepared',
    description: 'Campo di Competenza Informatica e Tecniche Scout',
    url: './',
    src: path.join(__dirname, 'src'),
    output: outputdir,
    layouts: path.join(__dirname, 'layouts'),
    partials: path.join(__dirname, 'partials'),
    assets: path.join(__dirname, 'assets'),
    menu: menu,
    squadriglie: squadriglie,
    esercitazioni: esercitazioni.templateVar(),
    documenti: materialeDocumentiGenerali,
    fotosrc: path.join(outputdir, 'diariofotografico/foto'),
    categories: categories,
    excludeFileToSync: ['.DS_Store', 'Thumbs.db','.gitignore'],
    authorizedExts: authorizedExts,
    debug_enable: env_debug
  }

  logger.info('PrepareResources', 'prepare directory');

  rimraf.sync(config.src);
  rimraf.sync(config.output);
  fs.ensureDirSync(config.src);

  /**
   * Copia ricorsivamente i file da src a dest.
   * Se `lowercase` è true, i nomi di file e cartelle saranno trasformati in minuscolo.
   * Con `filtro` (change foto-segnaletiche-codificate) si copiano solo i file
   * che la funzione approva: riceve il percorso relativo (con slash, dalla
   * radice della copia, es. "reparto/foto.jpg") e decide se entra nel sito;
   * le cartelle non vengono filtrate.
   */
  function prepareResources(logger, config, title, src, dest, lowercase = false, filtro, prefisso = '') {
    logger.info('PrepareResources', title);
    try {
      fs.ensureDirSync(dest);

      const items = fs.readdirSync(src, { withFileTypes: true });

      for (const item of items) {
        const originalName = item.name;
        const normalized = originalName.normalize('NFD'); // decomposizione
        const relativo = prefisso ? `${prefisso}/${originalName}` : originalName;

        // Se è nella lista di esclusione, salta
        if (config.excludeFileToSync.includes(originalName)) continue;

        const targetName = lowercase ? originalName.toLowerCase() : originalName;

        const srcPath = path.join(src, originalName);
        const destPath = path.join(dest, targetName);

        if (/[̀-ͯ]/.test(normalized)) { // caratteri combinanti (accenti, tilde ecc.)
          logger.error('File con accenti (combinati):', srcPath);
        }

        if (item.isDirectory()) {
          prepareResources(logger, config, title, srcPath, destPath, lowercase, filtro, relativo); // ricorsivo
        } else {
          if (filtro && !filtro(relativo)) {
            logger.warn('file non pubblicato (non riconosciuto tra i dati del sito): ' + relativo);
            continue;
          }
          fs.ensureDirSync(path.dirname(destPath));
          fs.copyFileSync(srcPath, destPath);
          if ( config.debug_enable ){
            logger.success(`${originalName} sync to ${destPath}`);
          }
        }
      }

      logger.success(`${title} completata!`);
    } catch (err) {
      logger.error(`${title} fallita!`);
      console.error(err);
    }
  }



  prepareResources(logger, config, 'copy assets css', './assets/css', path.join(config.output, 'css'));

  prepareResources(logger, config, 'copy first page src', home.src(), config.src);

  prepareResources(logger, config, 'copy esercitazioni src', esercitazioni.src(), path.join(config.src, 'esercitazioni'));

  prepareResources(logger, config, 'copy esercitazioni materiale', esercitazioni.srcAssets(), path.join(config.output, 'esercitazioni'));

  prepareResources(logger, config, 'copy angoli src', angolisq.src(), path.join(config.src, 'angolisq'), true);

  // FIXME: non copia la thumb della foto di gruppo
  // pubblicità selettiva (change foto-segnaletiche-codificate): in
  // reparto/ entrano nel sito solo le foto (e i thumb) dei codici noti al
  // json; i file estranei restano fuori, già segnalati dalla build angolisq
  const pubblicabiliReparto = angolisq.filePubblicabiliReparto();
  prepareResources(logger, config, 'copy angoli materiale', angolisq.srcAssets(),
    path.join(config.output, 'angolisq'), true,
    (relativo) => !relativo.startsWith('reparto/') || pubblicabiliReparto.has(relativo.slice('reparto/'.length)));

  prepareResources(logger, config, 'copy programmi src', programmi.src(), path.join(config.src, 'programmi'));

  prepareResources(logger, config, 'copy documenti generali src', documentiGenerali.src(), path.join(config.src, 'documenti'));

  // FIXME: il filename del ricordo campo non é preso dal json
  prepareResources(logger, config, 'copy documenti generali materiale', documentiGenerali.srcAssets(), path.join(config.output, 'documenti'));

  prepareResources(logger, config, 'copy varie src', varie.src(), path.join(config.src, 'varie'));

  prepareResources(logger, config, 'copy varie materiale', varie.srcAssets(), path.join(config.output, 'varie'));

  prepareResources(logger, config, 'copy diario fotografico src', diariofotografico.src(), path.join(config.src, 'diariofotografico'), true);

  prepareResources(logger, config, 'copy diario fotografico materiale', diariofotografico.srcAssets(), path.join(config.output, 'diariofotografico'), true);

  var generatore = new GeneratoreHTML(logger);

  generatore.genera(config);

  // logger.info('');
  // logger.info(' ------------- ');
  // logger.info(' test logging ');
  // logger.info(' ------------- ');
  // logger.info('');
  //
  // logger.test();

}

main().catch(function (err) {
  console.error('');
  console.error('Generatore: build fallita:');
  console.error(err && err.message ? err.message : err);
  if (process.env.DEBUG && err && err.stack) {
    console.error(err.stack);
  }
  process.exit(1);
});
