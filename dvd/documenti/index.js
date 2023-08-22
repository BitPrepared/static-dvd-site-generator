const fs = require('fs');
const fsextra = require('fs-extra');
const rimraf = require('rimraf');
const path = require('path');
const handlebars = require('handlebars');
//const imagemagick = require('imagemagick-native');
const gm = require('gm').subClass({imageMagick: true});

var DocumentiGenerali = function (logger, materiale) {
  this.logger = logger;
  this.materiale = materiale;
};

function valuta(logger, materiale) {
  var missing = [];
  materiale.forEach((currentValue, index, arr) => {
    logger.info(currentValue.title);
    var curDir = currentValue.dir;
    if (currentValue.dir) {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + curDir + '/'))) {
        missing.push(currentValue);
      }
      if (currentValue.files) {
        currentValue.files.forEach((currentValue, index, arr) => {
          if(currentValue.filename){
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

DocumentiGenerali.prototype.check = function () {
  var missing = [];
  this.logger.info('DocumentiGenerali', 'materiale');
  missing = missing.concat(valuta(this.logger, this.materiale));
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

DocumentiGenerali.prototype.build = function () {
  // wget --mirror -w 2 -p --convert-links --load-cookies cookies.txt -e robots=off --reject logout https://precampo.bitprepared.it
  // poi vanno fixati i link!

  const loggerParent = this.logger;

  // squadriglia
  const dirStaff = path.join(__dirname, 'materiale/staff/');
  if (fs.existsSync(dirStaff)) {
    fs.readdirSync(dirStaff).forEach(function (file) {
      if (file.indexOf('thumb_') < 0 && path.basename(file, path.extname(file)).indexOf('.') < 0) {
        const newFilename = 'thumb_' + path.basename(file);
        createThumb(loggerParent, path.join(dirStaff, file), path.join(dirStaff, newFilename), 650);
      }
    });
  }
}

DocumentiGenerali.prototype.clean = function () {

}

DocumentiGenerali.prototype.src = function () {
  return path.join(__dirname, 'src');
}

DocumentiGenerali.prototype.srcAssets = function () {
  return path.join(__dirname, 'materiale');
}

module.exports = DocumentiGenerali;
