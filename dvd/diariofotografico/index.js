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
  this.elencoEstensioniAmmesse = elencoEstensioniAmmesse;
};

DiarioFotografico.prototype.check = function () {
  this.logger.info('DiarioFotografico', 'check materiale');
  var missing = [];
  if (!fs.existsSync(path.join(__dirname, './materiale/foto/'))) {
    missing.push({
      "title": "cartella foto",
      "dir": "foto",
      "responsabile" : [
        "andrea", "samuele"
      ]
    });
  }
  return missing;
};

function createThumb(loggerParent, fullpathIn, fullpathOut) {
  if (!fs.existsSync(fullpathOut)) {
    loggerParent.info("create thumb " + path.basename(fullpathIn));

    gm(fs.readFileSync(fullpathIn)).resize(150,150).write(fullpathOut, function(err) {
      if (err) this.logger.error(err);
    });

    // fs.writeFileSync(fullpathOut, imagemagick.convert({
    //   srcData: fs.readFileSync(fullpathIn),
    //   quality: 95,
    //   width: 150,
    //   height: 150,
    //   resizeStyle: 'aspectfit',
    //   format: 'JPEG'
    // }));
  }
}

DiarioFotografico.prototype.build = function () {
  this.logger.info('DiarioFotografico', 'build');
  var contents = fs.readFileSync(path.join(__dirname, 'template/index.hbs'), 'utf8');
  fsextra.ensureDirSync(path.join(__dirname, 'src/'));
  fs.writeFileSync(path.join(__dirname, 'src/index.hbs'), contents);

  var contentsCategory = fs.readFileSync(path.join(__dirname, 'template/category.hbs'), 'utf8');
  this.categories.forEach(function(element) {
    var contentsCategoryR = contentsCategory.replace(new RegExp('##CATEGORY##', 'g'), element); 
    fs.writeFileSync(path.join(__dirname, 'src/' + element + '.hbs'), contentsCategoryR);
  });
  this.thumb();
}

DiarioFotografico.prototype.thumb = function () {
  this.logger.info('DiarioFotografico', 'create thumb');
  const destdir = path.join(__dirname, 'materiale/thumb/');
  fsextra.ensureDirSync(destdir);
  const fotoSrc = path.join(__dirname, 'materiale/foto/');
  const elencoEstensioni = this.elencoEstensioniAmmesse.join("|")
  const loggerParent = this.logger;
  const filteredTree = dirTree(fotoSrc, { extensions: new RegExp(".(" + elencoEstensioni + ")$") }, function (item, PATH) {
    const outputdir = item.path.replace(fotoSrc, '').replace(item.name, '');
    const outputname = item.name.replace(path.extname(item.path), '') + ".jpg";
    fsextra.ensureDirSync(destdir + outputdir);
    const output = destdir + outputdir + outputname;
    createThumb(loggerParent, item.path, output);
  });
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
