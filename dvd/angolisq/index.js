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

function createThumb(loggerParent, fullpathIn, fullpathOut, size) {
  if (!fs.existsSync(fullpathOut)) {
    loggerParent.info("create thumb of " + path.basename(fullpathIn));
    gm(fs.readFileSync(fullpathIn)).resize(size,size).write(fullpathOut, function(err) {
      if (err) this.logger.error(err);
    });

    // fs.writeFileSync(fullpathOut, imagemagick.convert({
    //   srcData: fs.readFileSync(fullpathIn),
    //   quality: 95,
    //   width: size,
    //   height: size,
    //   resizeStyle: 'aspectfit',
    //   format: 'JPEG'
    // }));
  }
}

function concat_ifnotempty($str, $append){
  if ( $append ){
    return $str.concat($append).concat(' ');
  }
  return $str;
}

Angolisq.prototype.build = function () {

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
      var filename = (squadrigliere.nome + squadrigliere.cognome).toLowerCase();
      filename = filename.replace(/\s/g, "");
      this.logger.info('found: ' + filename);
      const desc_name = squadrigliere.name + " " + squadrigliere.surname;
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


  // guidoni
  const dirGuidoni = path.join(__dirname, 'materiale/guidoni/');
  if (fs.existsSync(dirGuidoni) ){
    fs.readdirSync(dirGuidoni).forEach(function(file){
      if ( file.indexOf('thumb_') < 0 && path.basename(file, path.extname(file)).indexOf('.') < 0 ) {
        const newFilename = 'thumb_' + path.basename(file);
        createThumb(loggerParent, path.join(dirGuidoni, file), path.join(dirGuidoni, newFilename), 150 );
      }
    });  
  }

  // squadriglia
  const dirSquadriglia = path.join(__dirname, 'materiale/squadriglia/');
  if (fs.existsSync(dirSquadriglia)){
    fs.readdirSync(dirSquadriglia).forEach(function (file) {
      if (file.indexOf('thumb_') < 0 && path.basename(file, path.extname(file)).indexOf('.') < 0) {
        const newFilename = 'thumb_' + path.basename(file);
        createThumb(loggerParent, path.join(dirSquadriglia, file), path.join(dirSquadriglia, newFilename), 450);
      }
    });  
  }

  // reparto
  const dirReparto = path.join(__dirname, 'materiale/reparto/');
  if (fs.existsSync(dirReparto)){
    fs.readdirSync(dirReparto).forEach(function (file) {
      if (file.indexOf('thumb_') < 0 && path.basename(file, path.extname(file)).indexOf('.') < 0) {
        const newFilename = 'thumb_' + path.basename(file);
        createThumb(loggerParent, path.join(dirReparto, file), path.join(dirReparto, newFilename), 150);
      }
    });  
  }

  //sovrascrivo con una thumb piu grande
  //fsextra.removeSync(path.join(dirReparto, 'thumb_fotogruppo.jpg'));
  if (fs.existsSync(dirReparto)) {
    createThumb(loggerParent, path.join(dirReparto, 'fotogruppo.jpg'), path.join(dirReparto, 'thumb_fotogruppo.jpg'), 650);
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
