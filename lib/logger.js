const chalk = require('chalk');
const emoji = require('node-emoji');

var Logger = function(debug) { if ( debug ) { this.enableDebug = debug; } else { this.enableDebug = false; } };

Logger.prototype.title = function(title) {
  process.stdout.write(chalk.gray(emoji.emojify('[  ]') + title) + "\n");
};

Logger.prototype.success = function(message) {
  process.stdout.write(chalk.white('[') + chalk.green( emoji.emojify(':white_check_mark:')) + chalk.white(' ] ') + chalk.green(message)  + "\n" );
};

// [INFO] --- maven-compiler-plugin:3.6.0:compile (default-compile) @ unihubsign-main ---
// // [INFO] blah blah
Logger.prototype.info = function(info, moduleName) {
  if ( moduleName ) {
    process.stderr.write(chalk.white('[ ') + chalk.blue('INFO') + chalk.white(' ] --- ') + info + " @ " + chalk.cyan(moduleName) + chalk.white(' --- ') + "\n");
  } else {
    process.stderr.write(chalk.white('[ ') + chalk.blue('INFO') + chalk.white(' ] ') + info  + "\n");
  }
};

Logger.prototype.debug = function(debug, moduleName) {
  if (this.enableDebug){
    if ( moduleName ) {
      process.stderr.write(chalk.gray('[ ') + chalk.gray('DEBUG') + chalk.gray(' ] --- ') + debug + " @ " + chalk.cyan(moduleName) + chalk.gray(' --- ') + "\n");
    } else {
      process.stderr.write(chalk.gray('[ ') + chalk.gray('DEBUG') + chalk.gray(' ] ') + debug  + "\n");
    }
  }
};

Logger.prototype.warn = function(warn) {
  process.stderr.write(chalk.white('[') + chalk.yellow(emoji.emojify(':raised_hand:')) + chalk.white(' ] ') + chalk.yellow(warn) + "\n");
};

Logger.prototype.error = function(text, stdout, stderr) {
  //process.stderr.write(chalk.bgRed.white(emoji.emojify('[:heavy_multiplication_x: ] ') + text ) + "\n");
  process.stderr.write(chalk.white('[') + chalk.red(emoji.emojify(':x:')) + chalk.white(' ] ') + chalk.bgRed.white(text) + "\n");
  if (stdout) process.stderr.write(chalk.white('[ ') + chalk.red('ERROR') + chalk.white(' ] ') + chalk.gray(stdout + "\n"));
  if (stderr) process.stderr.write(chalk.white('[ ') + chalk.red('ERROR') + chalk.white(' ] ') + chalk.red(stderr + "\n"));
};

Logger.prototype.test = function() {
  this.info('info!', 'moduleName');
  this.info('text info');
  this.warn('warn text!');
  this.error('error text');
  this.error('error text with output','stdout', 'stderr');
  this.success('success');
};

module.exports = Logger;
