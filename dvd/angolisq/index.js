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

// Thumb di una cartella, generati in serie: la build della sezione termina
// solo quando sono tutti su disco (una sola make build).
// Con `attesi` (change foto-segnaletiche-codificate) si genera il thumb solo
// dei codici noti al json: i file estranei vengono segnalati e restano fuori
// dal sito (protegge dai vecchi sample con nomi reali rimasti sul disco).
async function creaThumbCartella(loggerParent, dir, size, attesi) {
  if (!fs.existsSync(dir)) {
    return;
  }
  const daGenerare = fs.readdirSync(dir).filter(function (file) {
    if (file.indexOf('thumb_') >= 0) return false;
    if (path.basename(file, path.extname(file)).indexOf('.') >= 0) return false;
    if (attesi && !attesi.has(path.basename(file, path.extname(file)))) {
      loggerParent.warn('reparto: file non riconosciuto tra i codici del json, nessun thumb e non pubblicato: ' + file);
      return false;
    }
    return true;
  });
  for (const file of daGenerare) {
    await createThumb(loggerParent, path.join(dir, file), path.join(dir, 'thumb_' + file), size);
  }
}

// Foto segnaletica di un codice in reparto/ (basename senza estensione,
// thumb escluse): null se non importata. L'estensione segue il file reale.
function fotoReparto(dirReparto, codice) {
  if (!fs.existsSync(dirReparto)) {
    return null;
  }
  const foto = fs.readdirSync(dirReparto).find(function (file) {
    return file.indexOf('thumb_') < 0 && path.basename(file, path.extname(file)) === codice;
  });
  return foto || null;
}

// Thumb a larghezza fissa con altezza in proporzione: per il fotogruppo,
// che la home pubblica a tutta colonna (template home width="650"), a
// differenza dei thumb piccoli della griglia reparto.
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

function concat_ifnotempty($str, $append){
  if ( $append ){
    return $str.concat($append).concat(' ');
  }
  return $str;
}

Angolisq.prototype.build = async function () {

  this.logger.info('Angolisq', 'build');

  fsextra.copySync(path.join(__dirname, 'template/index.hbs'), path.join(__dirname, 'src/index.hbs'));

  // codici attesi in reparto/ per la pubblicità selettiva delle foto
  // (fotogruppo compreso: è referenziato dalla home, non è un codice ragazzo)
  this.codiciAttesiReparto = new Set(['fotogruppo']);

  const dirReparto = path.join(__dirname, 'materiale/reparto');

  for (var key in this.squadriglie) {
    var element = this.squadriglie[key];
    const sqname = element.name.toLowerCase();
    const members = element.members;
    var contentsSq = fs.readFileSync(path.join(__dirname, 'template/sq.hbs'), 'utf8');
    contentsSq = contentsSq.replace(new RegExp('##NAMESQ##', 'g'), sqname);
    fsextra.ensureDirSync(path.join(__dirname, 'src/'));
    fs.writeFileSync(path.join(__dirname, 'src/' + sqname + '.hbs'), contentsSq);
    for (var keyM in members) {
      var squadrigliere = members[keyM];

      // la chiave del member è il codice dell'import (es. mr1_blu) o l'id
      // legacy nomecognome senza registro: in entrambi i casi è il nome file
      // della pagina e il pezzo del link {{@key}}.html in sq.hbs
      const filename = keyM;

      // foto segnaletica importata per questo codice? annota sul member ciò
      // che serve alla pagina squadriglia (griglia con estensione vera);
      // nel json su disco non finisce nulla
      const foto = fotoReparto(dirReparto, filename);
      squadrigliere.hafoto = !!foto;
      squadrigliere.fotosegn = foto ? ('thumb_' + foto) : '';
      this.codiciAttesiReparto.add(filename);

      // la scheda individuale nasce solo dai member con campo nome:
      // in modalità anonima i member sono soli codici ({}) e la pagina
      // squadriglia mostra solo la griglia di foto codificate
      if (!squadrigliere.nome) {
        continue;
      }
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

  // reparto: solo i codici noti al json (+ fotogruppo), gli estranei
  // vengono segnalati e non pubblicati.
  //
  // fotogruppo è particolare: la home lo pubblica a tutta colonna, quindi
  // la SUA thumb va creata LARGA 650 con altezza in proporzione — e PRIMA
  // del batch da 150, che altrimenti la crea piccola e per sempre (i thumb
  // esistenti non si rigenerano). La rimozione preventiva rende automatico
  // anche l'aggiornamento quando la foto di gruppo cambia: senza, sul disco
  // resterebbe per sempre la vecchia thumb.
  const fotogruppo = path.join(dirReparto, 'fotogruppo.jpg');
  if (fs.existsSync(fotogruppo)) {
    fsextra.removeSync(path.join(dirReparto, 'thumb_fotogruppo.jpg'));
    await createThumbLarga(loggerParent, fotogruppo, path.join(dirReparto, 'thumb_fotogruppo.jpg'), 650);
  }
  await creaThumbCartella(loggerParent, dirReparto + '/', 150, this.codiciAttesiReparto);

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

// Nomi di file (dentro materiale/reparto/) pubblicabili sul sito: le foto e
// i thumb dei codici noti al json più fotogruppo. Il generatore usa questo
// elenco per lasciare fuori tutto il resto (vecchi sample con nomi veri,
// file estranei): vedi prepareResources in static-dvd-site-generator.
Angolisq.prototype.filePubblicabiliReparto = function () {
  const attesi = this.codiciAttesiReparto || new Set(['fotogruppo']);
  const dir = path.join(__dirname, 'materiale/reparto');
  const ok = new Set();
  if (!fs.existsSync(dir)) {
    return ok;
  }
  for (const file of fs.readdirSync(dir)) {
    let base = path.basename(file, path.extname(file));
    if (base.indexOf('thumb_') === 0) {
      base = base.slice('thumb_'.length);
    }
    if (attesi.has(base)) {
      ok.add(file);
    }
  }
  return ok;
}

module.exports = Angolisq;
