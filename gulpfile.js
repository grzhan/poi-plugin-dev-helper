var gulp = require('gulp'),
	watch = require('gulp-watch');
var destDir = '../plugin_directory/poi-plugin-dev-helper'

gulp.task('watch', function() {
	watch('**/*.cjsx', function() {
		gulp.src('**/*.cjsx')
			.pipe(watch('**/*.cjsx'))
			.pipe(gulp.dest('../plugin_directory/poi-plugin-dev-helper'))
	});
});
