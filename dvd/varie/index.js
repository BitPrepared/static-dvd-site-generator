const fs = require('fs');
const fsextra = require('fs-extra');
const rimraf = require('rimraf');
const path = require('path');
const handlebars = require('handlebars');

var Varie = function (logger, materiale) {
  this.logger = logger;
  this.materiale = materiale;
};

// Percorso repo-relative dove si aspetta il materiale: compare nei messaggi
// "missing" per dire a chi builda dove mettere il file che manca.
function conAttesoIn(descrittore, percorso) {
  descrittore.attesoIn = percorso;
  return descrittore;
}

function valuta(logger, materiale) {
  var missing = [];
  materiale.forEach((currentValue, index, arr) => {
    logger.info(currentValue.title);
    if (currentValue.dir) {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.dir + '/'))) {
        missing.push(conAttesoIn(currentValue, 'dvd/varie/materiale/' + currentValue.dir + '/'));
      }
      if (currentValue.files) {
        currentValue.files.forEach((file) => {
          if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.dir + '/' + file.filename))) {
            missing.push(conAttesoIn(file, 'dvd/varie/materiale/' + currentValue.dir + '/' + file.filename));
          }
        });
      }

    } else {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.file))) {
        missing.push(conAttesoIn(currentValue, 'dvd/varie/materiale/' + currentValue.file));
      }
    }
  });
  return missing;
}

Varie.prototype.check = function () {
  var missing = [];
  this.logger.info('Varie', 'check materiale');
  missing = missing.concat(valuta(this.logger, this.materiale));
  return missing;
};

Varie.prototype.build = function () {

}

Varie.prototype.clean = function () {

}

Varie.prototype.src = function () {
  return path.join(__dirname, 'src');
}

Varie.prototype.srcAssets = function () {
  return path.join(__dirname, 'materiale');
}

module.exports = Varie;
