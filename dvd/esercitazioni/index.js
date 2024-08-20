var extend = require('util')._extend;
const fs = require('fs');
const path = require('path');

var Esercitazioni = function (logger, materiale, materialeAltreAttivita) {
  this.logger = logger;
  this.materiale = materiale;
  this.materialeAltreAttivita = materialeAltreAttivita;
};

function valuta(logger, materiale) {
  var missing = [];
  materiale.forEach((currentValue, index, arr) => {
    logger.info(currentValue.title);
    var curDir = currentValue.dir;
    if (curDir) {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.dir + '/'))) {
        missing.push(currentValue);
      }
      if ( currentValue.files ) {
        currentValue.files.forEach((currentValue, index, arr) => {
          if (currentValue.filename) {
            if (!fs.existsSync(path.join(__dirname, './materiale/' + curDir + '/' + currentValue.filename))) {
              missing.push(currentValue);
            }   
          }
        });
      }

    } else {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.file))) {
        missing.push(currentValue);
      }
    }
  });
  return missing;
}

Esercitazioni.prototype.check = function () {
  var missing = [];
  this.logger.info('Esercitazioni', 'workshop');
  missing = missing.concat(valuta(this.logger, this.materiale));
  this.logger.info('Esercitazioni', 'altre attivita');
  missing = missing.concat(valuta(this.logger, this.materialeAltreAttivita));
  return missing;
};

Esercitazioni.prototype.src = function () {
  return path.join(__dirname, 'src');
}

Esercitazioni.prototype.srcAssets = function () {
  return path.join(__dirname, 'materiale');
}

Esercitazioni.prototype.templateVar = function () {
  return {
    materialeWorkshop: this.materiale,
    materialeAltreAttivita: this.materialeAltreAttivita
  };
}



module.exports = Esercitazioni;
