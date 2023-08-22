const fs = require('fs');
const fsextra = require('fs-extra');
const rimraf = require('rimraf');
const path = require('path');
const handlebars = require('handlebars');

var Varie = function (logger, materiale) {
  this.logger = logger;
  this.materiale = materiale;
};

function valuta(logger, materiale) {
  var missing = [];
  materiale.forEach((currentValue, index, arr) => {
    logger.info(currentValue.title);
    if (currentValue.dir) {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.dir + '/'))) {
        missing.push(currentValue);
      }
      if (currentValue.files) {
        currentValue.files.forEach((currentValue, index, arr) => {
          if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.dir + '/' + currentValue.filename))) {
            missing.push(currentValue);
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
