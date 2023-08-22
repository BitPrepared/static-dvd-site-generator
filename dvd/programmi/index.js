const fs = require('fs');
const fsextra = require('fs-extra');
const rimraf = require('rimraf');
const path = require('path');
const handlebars = require('handlebars');

var Programmi = function (logger) {
  this.logger = logger;
};

Programmi.prototype.check = function () {
  this.logger.info('Programmi', 'materiale');
  return [];
};

Programmi.prototype.build = function () {

}

Programmi.prototype.clean = function () {

}

Programmi.prototype.src = function () {
  return path.join(__dirname, 'src');
}

Programmi.prototype.srcAssets = function () {
  return path.join(__dirname, 'materiale');
}

module.exports = Programmi;
