"use strict";

var gulp   = require("gulp")
  , util   = require("gulp-util")
  , concat = require("gulp-concat")
  , coffee = require("gulp-coffee")
  , bower  = require("bower")
  , stylus = require("gulp-stylus")
  , smaps  = require("gulp-sourcemaps")
  , uglify = require("gulp-uglify")
  , bmain  = require("main-bower-files");

var app = {
  js: ["lib/scripts/*.coffee"],
  css: ["lib/styles/*.styl"],
  html: ["lib/htmls/*.html"],
  dist: {
    dir: "dist",
    css: "main.css",
    deps: "deps.js"
  }
};

gulp.task("bower", function() {
  bower.commands.install.apply(bower.commands, [[], {}, bower.config])
    .on("log", function(result) {
      util.log([
        "bower",
        util.colors.cyan(result.id),
        result.message
      ].join(" "));
    })
    .on("end", function() {
      gulp.src(bmain())
        .pipe(smaps.init())
        .pipe(concat(app.dist.deps))
        .pipe(uglify({
          unsafe: true
        }))
        .pipe(smaps.write())
        .pipe(gulp.dest(app.dist.dir));
    });
});

gulp.task("scripts", function() {
  gulp.src(app.js)
    .pipe(smaps.init())
    .pipe(coffee())
    .pipe(uglify({
      unsafe: true
    }))
    .pipe(smaps.write())
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("styles", function() {
  gulp.src(app.css)
    .pipe(smaps.init())
    .pipe(stylus())
    .pipe(concat(app.dist.css))
    .pipe(smaps.write())
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("htmls", function() {
  gulp.src(app.html)
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("build", ["bower", "styles", "htmls", "scripts"]);

gulp.task("watch", ["build"], function() {
  gulp.watch(app.js[0], ["scripts"]);
  gulp.watch(app.css[0], ["styles"]);
  gulp.watch(app.html[0], ["htmls"]);
  gulp.watch("./bower.json", ["bower"]);
});

gulp.task("default", ["build"]);
