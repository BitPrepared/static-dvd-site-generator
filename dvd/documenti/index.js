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
    var curDir = currentValue.dir;
    if (currentValue.dir) {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + curDir + '/'))) {
        missing.push(conAttesoIn(currentValue, 'dvd/documenti/materiale/' + curDir + '/'));
      }
      if (currentValue.files) {
        currentValue.files.forEach((file) => {
          if(file.filename){
            if (!fs.existsSync(path.join(__dirname, './materiale/' + curDir + '/' + file.filename))) {
              missing.push(conAttesoIn(file, 'dvd/documenti/materiale/' + curDir + '/' + file.filename));
            }
          }
        });
      }

    } else {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.file))) {
        missing.push(conAttesoIn(currentValue, 'dvd/documenti/materiale/' + currentValue.file));
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

// Thumb a larghezza fissa con altezza in proporzione, promise-based come in
// dvd/angolisq (change fix-thumb-logger): la build aspetta che sia su disco
// e un fallimento esce con l'errore reale e il file coinvolto, invece di
// crashare su this.logger o completare in silenzio senza thumb.
function createThumbLarga(loggerParent, fullpathIn, fullpathOut, larghezza) {
  if (fs.existsSync(fullpathOut)) {
    return Promise.resolve(); // thumb già presente: non si rigenera
  }
  loggerParent.info('create thumb larga ' + larghezza + ' di ' + path.basename(fullpathIn));
  return new Promise((resolve, reject) => {
    gm(fs.readFileSync(fullpathIn)).resize(larghezza).write(fullpathOut, function(err) {
      if (err) {
        reject(new Error("thumb di " + fullpathIn + ": " + (err.message || err)));
        return;
      }
      resolve();
    });
  });
}

DocumentiGenerali.prototype.build = async function () {
  // wget --mirror -w 2 -p --convert-links --load-cookies cookies.txt -e robots=off --reject logout https://precampo.bitprepared.it
  // poi vanno fixati i link!

  const loggerParent = this.logger;

  // foto dello staff (pagina documenti/staff, width="650"): stessa regola
  // del fotogruppo dell'angolo squadriglie — thumb LARGA 650 con altezza in
  // proporzione, creata prima del rendering (la build la aspetta) e
  // rigenerata quando il sorgente cambia (rimozione preventiva della
  // vecchia thumb, altrimenti resterebbe per sempre quella precedente).
  const dirStaff = path.join(__dirname, 'materiale/staff/');
  if (fs.existsSync(dirStaff)) {
    const immagini = fs.readdirSync(dirStaff).filter(function (file) {
      return file.indexOf('thumb_') < 0 &&
        path.basename(file, path.extname(file)).indexOf('.') < 0;
    });
    for (const file of immagini) {
      const fullpathOut = path.join(dirStaff, 'thumb_' + file);
      fsextra.removeSync(fullpathOut);
      await createThumbLarga(loggerParent, path.join(dirStaff, file), fullpathOut, 650);
    }
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
