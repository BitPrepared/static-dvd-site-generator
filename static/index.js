// Base file config
const Home = require('./dvd/home/index.js');
const Esercitazioni = require('./dvd/esercitazioni/index.js');
const Angolisq = require('./dvd/angolisq/index.js');
const Programmi = require('./dvd/programmi/index.js');
const DocumentiGenerali = require('./dvd/documenti/index.js');
const Varie = require('./dvd/varie/index.js');
const DiarioFotografico = require('./dvd/diariofotografico/index.js');
const Blog = require('./dvd/blog/index.js');
const Logger = require('./lib/logger.js');
const GeneratoreHTML = require('./lib/generatore.js');
const path = require('path');
const rimraf = require('rimraf');

require('fs-extra-debug')
const fs = require('fs-extra');

const shell = require('shelljs');

const materialeAngoliSq = fs.readJsonSync(path.join(__dirname, 'dati/materialeAngoliSq.json'), 'utf8');
const materialeWorkshop = fs.readJsonSync(path.join(__dirname, 'dati/materialeWorkshop.json'), 'utf8');
const materialeDocumentiGenerali = fs.readJsonSync(path.join(__dirname, 'dati/materialeDocumentiGenerali.json'), 'utf8');
const materialeVarie = fs.readJsonSync(path.join(__dirname, 'dati/materialeVarie.json'), 'utf8');
const materialeAltreAttivita = fs.readJsonSync(path.join(__dirname, 'dati/materialeAltreAttivita.json'), 'utf8');
const squadriglie = fs.readJsonSync(path.join(__dirname, 'dati/squadriglie.json'), 'utf8');
const categories = fs.readJsonSync(path.join(__dirname, 'dati/categorieDiarioFotografico.json'), 'utf8');
const materialeDiarioFotografico = fs.readJsonSync(path.join(__dirname, 'dati/materialeDiarioFotografico.json'), 'utf8');

const authorizedExts = ['jpg', 'jpeg', 'svg', 'png', 'gif', 'JPG', 'JPEG', 'SVG', 'PNG', 'GIF'];

var menu = [
  {
    'url': 'esercitazioni/index.html',
    'alt': 'Impresa'
  },
  {
    'url': 'angolisq/index.html',
    'alt': 'Angoli di sq.'
  },
  {
    'url': 'blog/index.html',
    'alt': 'Blog'
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
  const responsabili = currentValue.responsabile.join(',');
  logger.warn('missing: ' + currentValue.title + '! Responsabile [' + responsabili + ']');
});
home.clean();
home.build();

var esercitazioni = new Esercitazioni(logger, materialeWorkshop, materialeAltreAttivita);
const missing = esercitazioni.check();
missing.forEach((currentValue, index, arr) => {
  if (currentValue.responsabile) {
    const responsabili = currentValue.responsabile.join(',');
    logger.warn('missing: '+currentValue.title+'! Responsabile ['+responsabili+']');
  } else {
    logger.warn('missing: ' + currentValue.description + '!');
  }
});

var angolisq = new Angolisq(logger, squadriglie, materialeAngoliSq);
const missingAngoli = angolisq.check();
missingAngoli.forEach((currentValue, index, arr) => {
  const responsabili = currentValue.responsabile.join(',');
  logger.warn('missing: ' + currentValue.title + '! Responsabile [' + responsabili + ']');
});
angolisq.clean();
angolisq.build();

var programmi = new Programmi(logger);
angolisq.check();

var blog = new Blog(logger);
const missingBlog = blog.check();
missingBlog.forEach((currentValue, index, arr) => {
  const responsabili = currentValue.responsabile.join(',');
  logger.warn('missing: ' + currentValue.title + '! Responsabile [' + responsabili + ']');
});

var documentiGenerali = new DocumentiGenerali(logger, materialeDocumentiGenerali);
const missingDocumentiGenerali = documentiGenerali.check();
missingDocumentiGenerali.forEach((currentValue, index, arr) => {
  if (currentValue.responsabile) {
    const responsabili = currentValue.responsabile.join(',');
    logger.warn('missing: ' + currentValue.title + '! Responsabile [' + responsabili + ']');
  } else {
    logger.warn('missing: ' + currentValue.description + '!');
  }
});
documentiGenerali.build();

var varie = new Varie(logger, materialeVarie);
const missingVarie = varie.check();
missingVarie.forEach((currentValue, index, arr) => {
  if (currentValue.responsabile) {
    const responsabili = currentValue.responsabile.join(',');
    logger.warn('missing: ' + currentValue.title + '! Responsabile [' + responsabili + ']');
  } else {
    logger.warn('missing: ' + currentValue.description + '!');
  }
});

var diariofotografico = new DiarioFotografico(logger, authorizedExts ,categories, materialeDiarioFotografico);
const missingDiario = diariofotografico.check();
missingDiario.forEach((currentValue, index, arr) => {
  if (currentValue.responsabile) {
    const responsabili = currentValue.responsabile.join(',');
    logger.warn('missing: ' + currentValue.title + '! Responsabile [' + responsabili + ']');
  } else {
    logger.warn('missing: ' + currentValue.description + '!');
  }
});

diariofotografico.clean();
diariofotografico.build();

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
  fotosrc: path.join(outputdir, 'diariofotografico/foto'),
  categories: categories,
  authorizedExts: authorizedExts
}

logger.info('PrepareResources', 'prepare directory');

rimraf.sync(config.src);
rimraf.sync(config.output);
fs.ensureDirSync(config.src);

function prepareResources(logger, title, src, dest) {
  logger.info('PrepareResources', title);
  try {
    fs.ensureDirSync(dest);
    fs.copySync(src, dest);
    logger.success(title + " completata!");
  } catch (err) {
    logger.error(title + " fallita!");
    console.error(err);
  }  
} 

prepareResources(logger, 'copy assets css', './assets/css', path.join(config.output, 'css'));

prepareResources(logger, 'copy first page src', home.src(), config.src);

prepareResources(logger, 'copy esercitazioni src', esercitazioni.src(), path.join(config.src, 'esercitazioni'));

prepareResources(logger, 'copy esercitazioni materiale', esercitazioni.srcAssets(), path.join(config.output, 'esercitazioni'));

prepareResources(logger, 'copy angoli src', angolisq.src(), path.join(config.src, 'angolisq'));

// FIXME: non copia la thumb della foto di gruppo
prepareResources(logger, 'copy angoli materiale', angolisq.srcAssets(), path.join(config.output, 'angolisq'));

prepareResources(logger, 'copy programmi src', programmi.src(), path.join(config.src, 'programmi'));

prepareResources(logger, 'copy documenti generali src', documentiGenerali.src(), path.join(config.src, 'documenti'));

// FIXME: il filename del ricordo campo non é preso dal json
prepareResources(logger, 'copy documenti generali materiale', documentiGenerali.srcAssets(), path.join(config.output, 'documenti'));

prepareResources(logger, 'copy varie src', varie.src(), path.join(config.src, 'varie'));

prepareResources(logger, 'copy varie materiale', varie.srcAssets(), path.join(config.output, 'varie'));

prepareResources(logger, 'copy diario fotografico src', diariofotografico.src(), path.join(config.src, 'diariofotografico'));

prepareResources(logger, 'copy diario fotografico materiale', diariofotografico.srcAssets(), path.join(config.output, 'diariofotografico'));

prepareResources(logger, 'copy blog materiale', blog.srcAssets(), path.join(config.output, 'blog'));

var generatore = new GeneratoreHTML(logger);

generatore.genera(config);

// logger.info('');
// logger.info(' ------------- ');
// logger.info(' test logging ');
// logger.info(' ------------- ');
// logger.info('');
//
// logger.test();