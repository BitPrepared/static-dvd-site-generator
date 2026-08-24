var extend = require('util')._extend;
const fs = require('fs');
const path = require('path');

var Esercitazioni = function (logger, materiale, materialeAltreAttivita) {
  this.logger = logger;
  this.materiale = materiale;
  this.materialeAltreAttivita = materialeAltreAttivita;
};

// Percorso repo-relative dove si aspetta il materiale: compare nei messaggi
// "missing" per dire a chi builda dove mettere il file che manca.
function conAttesoIn(descrittore, percorso) {
  descrittore.attesoIn = percorso;
  return descrittore;
}

// Cartelle libere ("qualcosa ci deve essere", nomi NON fissati): il
// descrittore dichiara cartella_libera e niente files[]; qui dentro si
// riempie files[] con quello che la cartella contiene, cosi' il template
// (che gia' cicla su files[]) linka tutto com'e'.
function riempiCartellaLibera(materiale) {
  materiale.forEach((currentValue) => {
    if (!currentValue.cartella_libera || !currentValue.dir) return;
    const dirCompleta = path.join(__dirname, './materiale/', currentValue.dir);
    currentValue.files = fs.existsSync(dirCompleta)
      ? fs.readdirSync(dirCompleta)
          .filter((f) => fs.statSync(path.join(dirCompleta, f)).isFile())
          .sort()
          .map((f) => ({ filename: f, description: f }))
      : [];
  });
}

function valuta(logger, materiale) {
  var missing = [];
  materiale.forEach((currentValue, index, arr) => {
    logger.info(currentValue.title);
    var curDir = currentValue.dir;
    if (curDir) {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.dir + '/'))) {
        var voce = conAttesoIn(currentValue, 'dvd/esercitazioni/materiale/' + currentValue.dir + '/');
        if (currentValue.cartella_libera) {
          voce.suggerimento = 'crea la cartella con almeno un file, qualunque nome: viene linkato com’è';
        }
        missing.push(voce);
      } else if (currentValue.cartella_libera) {
        if (!(currentValue.files && currentValue.files.length)) {
          missing.push(conAttesoIn({
            title: currentValue.title + ' (cartella vuota)',
            responsabile: currentValue.responsabile,
            suggerimento: 'basta un file, con qualunque nome: viene linkato com’è'
          }, 'dvd/esercitazioni/materiale/' + curDir + '/'));
        }
      } else if ( currentValue.files ) {
        currentValue.files.forEach((file) => {
          if (file.filename) {
            if (!fs.existsSync(path.join(__dirname, './materiale/' + curDir + '/' + file.filename))) {
              missing.push(conAttesoIn(file, 'dvd/esercitazioni/materiale/' + curDir + '/' + file.filename));
            }
          }
        });
      }

    } else {
      if (!fs.existsSync(path.join(__dirname, './materiale/' + currentValue.file))) {
        missing.push(conAttesoIn(currentValue, 'dvd/esercitazioni/materiale/' + currentValue.file));
      }
    }
  });
  return missing;
}

Esercitazioni.prototype.check = function () {
  var missing = [];
  riempiCartellaLibera(this.materiale);
  riempiCartellaLibera(this.materialeAltreAttivita);
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
