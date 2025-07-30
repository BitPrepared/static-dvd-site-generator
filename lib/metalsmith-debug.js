/*
metalsmith-debug
displays site metadata and page information in the console
*/
module.exports = function() {

	'use strict';

	return function(files, metalsmith, done) {

		console.log('\nMETADATA:');
		console.log(metalsmith.metadata());

		for (var f in files) {

			console.log('\nPAGE:');
			if ( files[f].layout !== undefined ) {
				console.log(files[f].layout);
			} 
			else {
				console.log(files[f]);
			}
			console.log(files[f].subtitle);

		}

		done();

	};

};
