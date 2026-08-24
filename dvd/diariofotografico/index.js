const fs = require('fs');
const fsextra = require('fs-extra');
const rimraf = require('rimraf');
const path = require('path');
const handlebars = require('handlebars');
//const imagemagick = require('imagemagick-native');
const gm = require('gm').subClass({imageMagick: true});
const dirTree = require('directory-tree');

var DiarioFotografico = function (logger, elencoEstensioniAmmesse, categories) {
  this.logger = logger;
  this.categories = categories;
  this.logger.info('DiarioFotografico', 'total categories: ' + this.categories.length);
  this.elencoEstensioniAmmesse = elencoEstensioniAmmesse;
};

DiarioFotografico.prototype.check = function () {
  this.logger.info('DiarioFotografico', 'check materiale');
  var missing = [];
  if (!fs.existsSync(path.join(__dirname, './materiale/foto/'))) {
    missing.push({
      "title": "cartella foto",
      "dir": "foto",
      "attesoIn": "dvd/diariofotografico/materiale/foto/",
      "responsabile" : [
        "andrea", "samuele"
      ]
    });
  }
  return missing;
};

// Genera un thumb se manca (se esiste non si rigenera). Restituisce una
// Promise: la callback di gm non usa this (che lì non è il plugin) ma il
// logger della closure, e un fallimento rigetta con l'errore reale di
// gm/ImageMagick e il file coinvolto.
function createThumb(loggerParent, fullpathIn, fullpathOut) {
  if (fs.existsSync(fullpathOut)) {
    return Promise.resolve(); // thumb già presente: non si rigenera
  }
  loggerParent.info("create thumb " + path.basename(fullpathIn));
  return new Promise((resolve, reject) => {
    gm(fs.readFileSync(fullpathIn)).resize(150,150).write(fullpathOut, function(err) {
      if (err) {
        reject(new Error("thumb di " + fullpathIn + ": " + (err.message || err)));
        return;
      }
      resolve();
    });
  });
}

// Diagnostica categorie: stessa regola ESATTA del plugin gallery — una
// cartella di secondo livello in foto/<giorno>/<categoria> finisce in una
// pagina categoria solo se il suo nome coincide letteralmente con una voce
// di dati/categorieDiarioFotografico.json (maiuscole e underscore contano).
// Una cartella non dichiarata non ha pagina categoria (le sue foto restano
// solo nella pagina del giorno); una categoria dichiarata senza cartella
// genera una pagina vuota.
DiarioFotografico.prototype.controllaCategorie = function () {
  const fotoSrc = path.join(__dirname, 'materiale/foto/');
  if (!fs.existsSync(fotoSrc)) {
    return;
  }
  const dichiarate = new Set(this.categories);
  const trovate = new Set();
  fs.readdirSync(fotoSrc).forEach((giorno) => {
    const perGiorno = path.join(fotoSrc, giorno);
    if (!fs.lstatSync(perGiorno).isDirectory()) {
      return;
    }
    // il giorno e' esso stesso una pagina: il plugin ci mette le foto del giorno
    trovate.add(giorno);
    fs.readdirSync(perGiorno).forEach((categoria) => {
      const perCategoria = path.join(perGiorno, categoria);
      if (!fs.lstatSync(perCategoria).isDirectory()) {
        return;
      }
      trovate.add(categoria);
      if (!dichiarate.has(categoria)) {
        this.logger.warn('foto: la cartella "' + categoria + '" (in ' + giorno +
          '/) non corrisponde a nessuna categoria dichiarata in ' +
          'dati/categorieDiarioFotografico.json: le sue foto non avranno una ' +
          'pagina categoria (aggiungi la categoria o rinomina la cartella)');
      }
    });
  });
  dichiarate.forEach((categoria) => {
    if (!trovate.has(categoria)) {
      this.logger.warn('categoria "' + categoria +
        '" senza nessuna cartella in foto/: la sua pagina verra\' generata vuota');
    }
  });
};

DiarioFotografico.prototype.build = async function () {
  this.logger.info('DiarioFotografico', 'build');
  this.controllaCategorie();
  var contents = fs.readFileSync(path.join(__dirname, 'template/index.hbs'), 'utf8');
  fsextra.ensureDirSync(path.join(__dirname, 'src/'));
  fs.writeFileSync(path.join(__dirname, 'src/index.hbs'), contents);

  var contentsCategory = fs.readFileSync(path.join(__dirname, 'template/category.hbs'), 'utf8');
  this.categories.forEach(function(element) {
    this.logger.info('DiarioFotografico', 'category: ' + element);
    var contentsCategoryR = contentsCategory.replace(new RegExp('##CATEGORY##', 'g'), element);
    fs.writeFileSync(path.join(__dirname, 'src/' + element + '.hbs'), contentsCategoryR);
  }.bind(this));
  await this.thumb();
}

// Thumb di tutte le foto del diario, generati in serie: la build della
// sezione termina solo quando sono tutti su disco (una sola make build).
DiarioFotografico.prototype.thumb = async function () {
  this.logger.info('DiarioFotografico', 'create thumb');
  const destdir = path.join(__dirname, 'materiale/thumb/');
  fsextra.ensureDirSync(destdir);
  const fotoSrc = path.join(__dirname, 'materiale/foto/');
  const elencoEstensioni = this.elencoEstensioniAmmesse.join("|")
  const loggerParent = this.logger;
  const foto = [];
  dirTree(fotoSrc, { extensions: new RegExp(".(" + elencoEstensioni + ")$") }, function (item, PATH) {
    foto.push(item);
  });
  for (const item of foto) {
    const outputdir = item.path.replace(fotoSrc, '').replace(item.name, '');
    const outputname = item.name.replace(path.extname(item.path), '') + ".jpg";
    fsextra.ensureDirSync(destdir + outputdir);
    await createThumb(loggerParent, item.path, destdir + outputdir + outputname);
  }
}

DiarioFotografico.prototype.clean = function () {
  this.logger.info('DiarioFotografico', 'clean');
  rimraf.sync(path.join(__dirname, 'src'));
  // NB: mantengo le vecchie thumb per performance/tempo di ri-generazione
  // rimraf.sync(path.join(__dirname, 'materiale/thumb/'));
}

DiarioFotografico.prototype.src = function () {
  return path.join(__dirname, 'src');
}

DiarioFotografico.prototype.srcAssets = function () {
  return path.join(__dirname, 'materiale');
}

module.exports = DiarioFotografico;
