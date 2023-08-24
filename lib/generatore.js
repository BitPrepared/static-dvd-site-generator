const Metalsmith = require('metalsmith');
const markdown = require('metalsmith-markdown');
/* const asciidoc = require('metalsmith-asciidoc'); */
const handlebars = require('handlebars');
const hbtmd = require('metalsmith-hbt-md');
const renamer = require('metalsmith-renamer');
const ancestry = require("metalsmith-ancestry");
const layouts = require('metalsmith-layouts');
const layoutsByName = require('metalsmith-layouts-by-name');
const permalinks = require('metalsmith-permalinks');
const assets = require('metalsmith-assets');
const links = require("metalsmith-relative-links");
const rootpath = require('metalsmith-rootpath');
const handlebarsIntl = require('handlebars-intl');
handlebarsIntl.registerWith(handlebars);
const helpers = require('handlebars-helpers')({
    handlebars: handlebars
});

const path = require('path');

// custom lib
// const debug = require('./metalsmith-debug');
const gallery = require('./metalsmith-gallery');
const savesrc = require('./metalsmith-savesrc');

var GeneratoreHTML = function (logger) { this.logger = logger; };

handlebars.registerHelper('if_eq', function (a, b, opts) {
    if (a == b) // Or === depending on your needs
        return opts.fn(this);
    else
        return opts.inverse(this);
});

handlebars.registerHelper('if_modzero', function (a, b, opts) {
    if (a % b == 0) // Or === depending on your needs
        return opts.fn(this);
    else
        return opts.inverse(this);
});

handlebars.registerHelper("debug", function (optionalValue) {
    if (optionalValue) {
        console.log("Value");
        console.log("====================");
        console.log(optionalValue);
    } else {
        console.log("Current Context");
        console.log("====================");
        console.log(this);
    }
});

handlebars.registerHelper('concat', function (value) {
    return value.hash.a + value.hash.b;
});

GeneratoreHTML.prototype.genera = function (config) {
    const loggerParent = this.logger;

    this.logger.info('GeneratoreHTML', 'metalsmith HTML setup');

    this.logger.info('Source: ' + config.src);

    this.logger.info('Layouts: ' + config.layouts);

    this.logger.info('Partials: ' + config.partials);

    const metalsmith = Metalsmith(__dirname)
        .metadata({
            title: config.title,
            description: config.description,
            generator: "Metalsmith",
            url: config.url,
            menu: config.menu,
            squadriglie: config.squadriglie,
            esercitazioni: config.esercitazioni
        })
        .source(config.src)
        .destination(config.output)
        .clean(false) //viene gia arrichita build precedentemente
        .use(rootpath())
        .use(assets({ source: config.assets }))
        .use(links({
            // // Name of property that should get the link function
            // linkProperty: "link",
            //
            // // Pattern of files to match
            // match: "**/*.htm,html",

            // Function to modify links.  See below.
            modifyLinks: function (uri) {
                const x = uri.replace(/\.md$/, ".html"); //.replace(/(^|\/|\\)index.html$/, "$1");
                return x.replace(/(^|\/|\\)$/, "$1/index.html").replace('\/\/', '\/');
            }
        }))
        .use(ancestry({
            match: '**/*',
            sortFilesFirst: "**/index.{html,md,hbs}",
            sortBy: function (a, b) {
                loggerParent.debug('ancestry', 'sortBy date');
                loggerParent.debug('Date A: ' + a.date);
                loggerParent.debug('Date B: ' + b.date);
                // 1 -> a piu grnade
                // -1 -> a piu piccolo
                if (a.date) {
                    if (b.date) {
                        if (new Date(a.date) == new Date(b.date)) return 0;
                        if (new Date(a.date) > new Date(b.date)) {
                            loggerParent.debug('vince a');
                            return 1;
                        }
                        loggerParent.debug('vince b');
                        return -1;
                    } else {
                        loggerParent.debug("b undefined");
                        // metto per primo chi ha la data
                        return 1;
                    }
                } else {
                    if (b.date) {
                        loggerParent.debug("a undefined");
                        // metto per primo chi ha la data
                        return -1;
                    } else {
                        return 0;
                    }
                }
            }
        }))
        .use(gallery({
            "imagesDirectory": config.fotosrc,
            "imagesKey": "galleries",
            "pattern": "**/*.hbs",
            "authorizedCategorie": config.categories,
            "authorizedExts": config.authorizedExts
        }))
        .use(hbtmd(handlebars, {
            pattern: '**/*.{md,hbs}'
        }))
        .use(permalinks({
            relative: true,
            pattern: ':title',
        }))
        .use(markdown({
            gfm: true,
            tables: true,
            breaks: true
        }))
        // .use(asciidoc())
        .use(layoutsByName({
            directory: config.layouts
        }))
        .use(layouts({
            engine: 'handlebars',
            directory: config.layouts,
            partials: config.partials,
            pretty: true
        }))
        .use(renamer({
            filesToRename: {
                pattern: '**/*.hbs',
                rename: function (name) {
                    return path.basename(name,'.hbs') + ".html";
                }
            }
        }))
        .use(savesrc());

    loggerParent.info('GeneratoreHTML', 'metalsmith build');

    loggerParent.info('Output dir '+ config.output);

    metalsmith.build((error, files) => {
        if (error) {
            loggerParent.error('Build with error!', '', error);
            console.log(error);
        } else {
            loggerParent.success('Build finished!');
        }
    });
};

module.exports = GeneratoreHTML;