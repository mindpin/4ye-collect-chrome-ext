"use strict";

var gulp   = require("gulp")
  , util   = require("gulp-util")
  , concat = require("gulp-concat")
  , coffee = require("gulp-coffee")
  , bower  = require("bower")
  , sass   = require("gulp-ruby-sass")
  , haml   = require("gulp-ruby-haml")
  , smaps  = require("gulp-sourcemaps")
  , bmain  = require("main-bower-files");

var app = {
  js: ["lib/scripts/*.coffee"],
  css: ["lib/styles/*.scss"],
  html: ["lib/htmls/*.haml"],
  manifest: "manifest.json",
  icon: "icon.png",
  dist: {
    dir: "dist",
    css: "main.css",
    deps: "deps.js",
    manifest: "manifest.json",
    icon: "icon.png"
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
        .pipe(smaps.write())
        .pipe(gulp.dest(app.dist.dir));
    });
});

gulp.task("scripts", function() {
  gulp.src(app.js)
    .pipe(smaps.init())
    .pipe(coffee())
    .pipe(smaps.write())
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("styles", function() {
  gulp.src(app.css)
    .pipe(sass())
    .on("error", function(err) {
      var file = err.message.match(/^error\s([\w\.]*)\s/)[1];

      util.log([
        err.plugin,
        util.colors.red(file),
        err.message
      ].join(" "));
    })
    .pipe(concat(app.dist.css))
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("htmls", function() {
  gulp.src(app.html)
    .pipe(haml())
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("manifest", function() {
  gulp.src(app.manifest)
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("icon", function() {
  gulp.src(app.icon)
    .pipe(gulp.dest(app.dist.dir));
});

gulp.task("build", ["bower", "styles", "htmls", "scripts", "manifest", "icon"]);

gulp.task("watch", ["build"], function() {
  gulp.watch(app.js[0], ["scripts"]);
  gulp.watch(app.css[0], ["styles"]);
  gulp.watch(app.html[0], ["htmls"]);
  gulp.watch(app.manifest, ["manifest"]);
  gulp.watch("./bower.json", ["bower"]);
});

gulp.task("default", ["build"]);
