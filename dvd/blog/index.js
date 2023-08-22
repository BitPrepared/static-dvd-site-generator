const fs = require('fs');
const fsextra = require('fs-extra');
const rimraf = require('rimraf');
const path = require('path');
const handlebars = require('handlebars');

var Blog = function (logger) {
    this.logger = logger;
};

Blog.prototype.check = function () {
    this.logger.info('Blog', 'check materiale');
    var missing = [];
    if (!fs.existsSync(path.join(__dirname, 'materiale/index.html'))) {
        missing.push({
            "title": "blog export",
            "description": "export del blog interno",
            "dir": "materiale",
            "responsabile": [
                "Daniele"
            ]
        });
    }
    return missing;
};

Blog.prototype.build = function () {

}

Blog.prototype.clean = function () {

}

Blog.prototype.src = function () {
    return path.join(__dirname, 'src');
}

Blog.prototype.srcAssets = function () {
    return path.join(__dirname, 'materiale');
}

module.exports = Blog;
