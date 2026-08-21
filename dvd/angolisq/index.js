const fs = require('fs');
const fsextra = require('fs-extra');
const rimraf = require('rimraf');
const path = require('path');
const handlebars = require('handlebars');
//const imagemagick = require('imagemagick-native');
const gm = require('gm').subClass({imageMagick: true});
const moment = require('moment');

var Angolisq = function (logger, squadriglie, materiale) {
  this.logger = logger;
  this.materiale = materiale;
  this.squadriglie = squadriglie;
};

function valuta(logger, materiale, squadriglie) {
  var missing = [];
  materiale.forEach((currentValue, index, arr) => {
    logger.info(currentValue.title);
    if (currentValue.dir) {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.dir + '/'))) {
        missing.push(currentValue);
      }
    } else {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.file))) {
        missing.push(currentValue);
      }
    }
  });
  return missing;
}

Angolisq.prototype.check = function () {
  this.logger.info('DiarioFotografico', 'check materiale');
  var missing = [];
  this.logger.info('Angolisq', 'materiale');
  missing = missing.concat(valuta(this.logger, this.materiale, this.squadriglie));
  return missing;
};

// Genera un thumb se manca (se esiste non si rigenera). Restituisce una
// Promise: la callback di gm non usa this (che lì non è il plugin) ma il
// logger della closure, e un fallimento rigetta con l'errore reale di
// gm/ImageMagick e il file coinvolto.
function createThumb(loggerParent, fullpathIn, fullpathOut, size) {
  if (fs.existsSync(fullpathOut)) {
    return Promise.resolve(); // thumb già presente: non si rigenera
  }
  loggerParent.info("create thumb of " + path.basename(fullpathIn));
  return new Promise((resolve, reject) => {
    gm(fs.readFileSync(fullpathIn)).resize(size,size).write(fullpathOut, function(err) {
      if (err) {
        reject(new Error("thumb di " + fullpathIn + ": " + (err.message || err)));
        return;
      }
      resolve();
    });
  });
}

// Thumb di tutti i file di una cartella, generati in serie: la build della
// sezione termina solo quando sono tutti su disco (una sola make build).
async function creaThumbCartella(loggerParent, dir, size) {
  if (!fs.existsSync(dir)) {
    return;
  }
  const daGenerare = fs.readdirSync(dir).filter(function (file) {
    return file.indexOf('thumb_') < 0 && path.basename(file, path.extname(file)).indexOf('.') < 0;
  });
  for (const file of daGenerare) {
    await createThumb(loggerParent, path.join(dir, file), path.join(dir, 'thumb_' + file), size);
  }
}

function concat_ifnotempty($str, $append){
  if ( $append ){
    return $str.concat($append).concat(' ');
  }
  return $str;
}

Angolisq.prototype.build = async function () {

  this.logger.info('Angolisq', 'build');

  fsextra.copySync(path.join(__dirname, 'template/index.hbs'), path.join(__dirname, 'src/index.hbs'));

  // var template = fs.readFileSync(path.join(__dirname, 'template/index.hbs'), 'utf8');
  // var templateScript = handlebars.compile(template);
  // var context = { "name": "Ritesh Kumar", "occupation": "developer" };
  // var html = templateScript(context);

  for (var key in this.squadriglie) {
    var element = this.squadriglie[key];
    const sqname = element.name.toLowerCase();
    const members = element.members;
    var contents = fs.readFileSync(path.join(__dirname, 'template/sq.hbs'), 'utf8');
    contents = contents.replace(new RegExp('##NAMESQ##', 'g'), sqname); //replace('##NAMESQ##', sqname);
    fsextra.ensureDirSync(path.join(__dirname, 'src/'));
    fs.writeFileSync(path.join(__dirname, 'src/' + sqname + '.hbs'), contents);
    for (var keyM in members) {
      var squadrigliere = members[keyM];
      // il filename della pagina è la chiave del member (id ASCII già
      // calcolato da genera_anagrafica): il link {{@key}}.html in sq.hbs
      // porta esattamente qui, cognomi accentati compresi
      const filename = keyM;
      this.logger.info('found: ' + filename);
      const desc_name = squadrigliere.nome + " " + squadrigliere.cognome;
      var contents = fs.readFileSync(path.join(__dirname, 'template/squadrigliere.hbs'), 'utf8');
      contents = contents.replace(new RegExp('##NAMESQ##', 'g'), sqname);
      contents = contents.replace(new RegExp('##NAMESQUADRIGLIERE##', 'g'), desc_name);
      contents = contents.replace(new RegExp('##IDSQUADRIGLIERE##', 'g'), filename);
      fsextra.ensureDirSync(path.join(__dirname, 'src/'));
      fs.writeFileSync(path.join(__dirname, 'src/' + filename + '.hbs'), contents);

      const datanascita = moment(squadrigliere.dtnascita,'DDMMYYYY');
      squadrigliere.dtnascitadisplay = datanascita.format('DD/MM/YYYY');

      var indirizzoStr = 'via ';
      indirizzoStr = concat_ifnotempty(concat_ifnotempty(indirizzoStr, squadrigliere.via), squadrigliere.ncivico);
      indirizzoStr = concat_ifnotempty(concat_ifnotempty(indirizzoStr, squadrigliere.cap), squadrigliere.citta);
      indirizzoStr = concat_ifnotempty(concat_ifnotempty(indirizzoStr, ' ('), squadrigliere.provincia);
      squadrigliere.indirizzo = indirizzoStr.concat(')');

      if (squadrigliere.specialita ){
        squadrigliere.specialita = squadrigliere.specialita.replace(new RegExp('_', 'g'), ' ');
      }
    }

  }

  const loggerParent = this.logger;

  // thumb attese in serie: alla fine di build() sono tutti su disco
  // guidoni
  await creaThumbCartella(loggerParent, path.join(__dirname, 'materiale/guidoni/'), 150);

  // squadriglia
  await creaThumbCartella(loggerParent, path.join(__dirname, 'materiale/squadriglia/'), 450);

  // reparto
  await creaThumbCartella(loggerParent, path.join(__dirname, 'materiale/reparto/'), 150);

  //sovrascrivo con una thumb piu grande
  //fsextra.removeSync(path.join(dirReparto, 'thumb_fotogruppo.jpg'));
  const fotogruppo = path.join(__dirname, 'materiale/reparto/fotogruppo.jpg');
  if (fs.existsSync(fotogruppo)) {
    await createThumb(loggerParent, fotogruppo, path.join(__dirname, 'materiale/reparto/thumb_fotogruppo.jpg'), 650);
  }

}

Angolisq.prototype.clean = function () {
  rimraf.sync(path.join(__dirname, 'src'));
}

Angolisq.prototype.src = function () {
  return path.join(__dirname, 'src');
}

Angolisq.prototype.srcAssets = function () {
  return path.join(__dirname, 'materiale');
}

module.exports = Angolisq;
