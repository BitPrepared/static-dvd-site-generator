/*
metalsmith-gallery

Strutture

--- directory src (Es: foto)
  | --- giorno
     | --- categoria
  | --- giorno
     | --- categoria


*/

const match = require('multimatch');
const debug = require('debug')('metalsmith-hbt-md');
const extend = require('util')._extend;
const fs = require('fs');
const path = require('path');
const dirTree = require('directory-tree');

/**
 * @param {Object} options
 * @param {Array} authorized extensions - e.g ['jpg', 'png', 'gif']
 * @return {Object}
 */
function normalizeOptions(options) {
    // define options
    var defaultOptions = {
        authorizedExts: ['jpg', 'jpeg', 'svg', 'png', 'gif', 'JPG', 'JPEG', 'SVG', 'PNG', 'GIF'],
        imagesDirectory: 'images',
        imagesKey: 'images',
        authorizedCategories: [],
        categoriesKey: "categories",
        pattern: "**/*.md"
    };

    return extend(defaultOptions, options);
}

module.exports.normalizeOptions = normalizeOptions;

/**
 * @param {String} file
 * @param {Array} authorized extensions - e.g ['jpg', 'png', 'gif']
 * @return {Boolean}
 */
function isAuthorizedFile(file, authorizedExtensions) {
    // get extension
    var extension = file.split('.').pop();
    return authorizedExtensions.indexOf(extension) > -1;
}

module.exports.isAuthorizedFile = isAuthorizedFile;

module.exports = function (options) {

    'use strict';

    options = normalizeOptions(options);

    return function (files, metalsmith, done) {

        // fs.readdirSync(options.imagesDirectory).forEach(element => {
        //     if (!fs.lstatSync(options.imagesDirectory + "/" + element).isDirectory() ) {
        //         const file = element;
        //         if (isAuthorizedFile(file, options.authorizedExts)) {
        //             console.log(file);
        //             // var imagePath = path.join(files[file].path.dir, options.imagesDirectory, dirFile);
        //             // files[file][options.imagesKey].push(imagePath);
        //         }
        //     } else {
        //         console.log("dir "+element);
        //     }
        // })

        const elencoEstensioni = options.authorizedExts.join("|")
        const filteredTree = dirTree(options.imagesDirectory, { extensions: new RegExp(".(" + elencoEstensioni + ")$") });

        var gallery = {};
        var categorie = [];

        if (filteredTree){
            filteredTree.children.forEach(function(item){
                if (fs.lstatSync(item.path).isDirectory()) {
                    debug("giorno: " + item.name);
                    const giorno = item.name;
                    gallery[giorno] = [];
                    item.children.forEach(function(item){
                        if (fs.lstatSync(item.path).isDirectory()) {
                            debug("categoria: " + item.name);
                            const categoria = item.name;
                            categorie.push(categoria);
                            gallery[categoria] = [];
                            item.children.forEach(function (item) {
                                debug("foto: " + item.name);
                                const name = path.basename(item.name, path.extname(item.name));
                                var obj = {
                                    "name": name,
                                    "filename": path.basename(item.path),
                                    "path": item.path.replace(options.imagesDirectory,''),
                                    "pathThumb": item.path.replace(options.imagesDirectory, '').replace(path.basename(item.path),'') + name + ".jpg"
                                };
                                if (categorie.indexOf(giorno) < 0 ){
                                    categorie.push(giorno);
                                }
                                gallery[giorno].push(obj);
                                gallery[categoria].push(obj);
                            });
                        }
                    });
                }
            });
        }

        if ( options.authorizedCategorie.length != 0 ){
            categorie = categorie.filter(function (i) { return options.authorizedCategorie.indexOf(i) > -1; })
        }

        Object.keys(files).forEach(function (file) {

            if (match(file, options.pattern).length === 0) {
                return;
            }

            debug('Processing ' + file);

            var fileStore = files[file];
            // var source = file.contents.toString();
            // var template = handlebars.compile(source, options);
            // var data = Object.assign({}, meta, file);

            // try {
            //     file.contents = new Buffer(template(data));
            //     debug('Processed ' + file);
            // } catch (e) {
            //     console.log(e.message);
            // }
            files[file][options.imagesKey] = gallery || [];
            files[file][options.categoriesKey] = categorie || [];
        });

        done();

    };

};
