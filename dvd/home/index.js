const fs = require('fs');
const fsextra = require('fs-extra');
const path = require('path');
const rimraf = require('rimraf');

var Home = function (logger) {
    this.logger = logger;
    this.materiale = [
        {
            "title": "Lettera",
            "file": "lettera/lettera.md",
            "responsabile": ["Elena", "Luciano"]
        },
        {
            "title": "Sublettera",
            "file": "lettera/sublettera.md",
            "responsabile": ["Elena", "Luciano"]
        }
    ]
};

function valuta(logger, materiale) {
    var missing = [];
    materiale.forEach((currentValue, index, arr) => {
        logger.info(currentValue.title);
        if (currentValue.dir){
            if (!fs.existsSync(path.join(__dirname,'./materiale/' + currentValue.dir + '/'))) {
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

Home.prototype.check = function () {
    var missing = [];
    this.logger.info('Home', 'materiali');
    missing = missing.concat(valuta(this.logger, this.materiale));
    return missing;
};

Home.prototype.build = function () {
    var contents = fs.readFileSync( path.join(__dirname, 'template/index.hbs'), 'utf8');
    if (fs.existsSync(path.join(__dirname, 'materiale/lettera/lettera.md'))) {
        var lettera = fs.readFileSync(path.join(__dirname, 'materiale/lettera/lettera.md'), 'utf8');
        contents = contents.replace('##LETTERA##', lettera);
    }
    if (fs.existsSync(path.join(__dirname, 'materiale/lettera/sublettera.md'))) {
        var testo = fs.readFileSync(path.join(__dirname, 'materiale/lettera/sublettera.md'), 'utf8');
        contents = contents.replace('##SUBLETTERA##', testo);
    }
    fsextra.ensureDirSync(path.join(__dirname, 'src/') );
    fs.writeFileSync( path.join(__dirname,'src/index.hbs'),contents);
}

Home.prototype.clean = function () {
    rimraf.sync(path.join(__dirname,'src'));
}

Home.prototype.src = function () {
    return path.join(__dirname, 'src');
}

module.exports = Home;
