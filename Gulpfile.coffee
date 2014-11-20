gulp = require('gulp')
source = require('vinyl-source-stream')
buffer = require('vinyl-buffer')
util = require('gulp-util')
plumber = require('gulp-plumber')
sourcemaps = require('gulp-sourcemaps')
filter = require('gulp-filter')
newer = require('gulp-newer')
extend = require('xtend')
_ = require('lodash')

# default environment to development
process.env.NODE_ENV or= 'development'

env = process.env
nodeEnv = env.NODE_ENV

lr = undefined
errorHandler = (err) ->
  util.beep()
  util.log(util.colors.red(err))

#
# css
#
myth = require('gulp-myth')
cssmin = require('gulp-minify-css')

css = ->

  gulp.src("src/css/index.css")
    .pipe(plumber(
      errorHandler: (err) ->
        errorHandler(err)
        # https://github.com/floatdrop/gulp-plumber/issues/8
        this.emit('end')
    ))
    .pipe(myth())
    .pipe(sourcemaps.init(loadMaps: true))
    .pipe(if nodeEnv == 'production' then cssmin() else util.noop())
    .pipe(sourcemaps.write('../maps'))
    .pipe(gulp.dest('build/css'))
    .pipe(if lr then require('gulp-livereload')(lr) else util.noop())

gulp.task 'css-build', css
gulp.task 'css-watch', ['css-build'], ->
  gulp.watch('src/css/**/*.css', ['css-build'])

#
# js
#
browserify = require('browserify')
mold = require('mold-source-map')

js = (isWatch) ->
  ->
    plugin = (bundler) ->
      bundler
        .plugin(require('bundle-collapser/plugin'))

    bundle = (bundler) ->
      bundler.bundle()
        .on('error', util.log.bind(util, "browserify error"))
        .pipe(plumber({ errorHandler }))
        #.pipe(mold.transformSourcesRelativeTo('./src/js'))
        .pipe(source('index.js'))
        .pipe(buffer())
        .pipe(sourcemaps.init(loadMaps: true))
        .pipe(if nodeEnv == 'production' then require('gulp-uglify')() else util.noop())
        .pipe(sourcemaps.write('../maps'))
        .pipe(gulp.dest('build/js'))
        .pipe(if lr then require('gulp-livereload')(lr) else util.noop())

    args = {
      entries: ['.']
      debug: true
    }

    if (isWatch)
      watchify = require('watchify')
      bundler = watchify(browserify(extend(args, watchify.args)))
      rebundle = -> bundle(bundler)
      bundler.on('update', rebundle)
      bundler.on('log', console.log.bind(console))
      rebundle()
    else
      bundle(plugin(browserify(args)))

gulp.task 'js-build', js(false)
gulp.task 'js-watch', js(true)

#
# html
#
filter = require('gulp-filter')
renderbars = require('gulp-renderbars')
prettify = require('gulp-prettify')

html = ->
  gulp.src("src/html/**/*")
    .pipe(plumber(
      errorHandler: (err) ->
        errorHandler(err)
        # https://github.com/floatdrop/gulp-plumber/issues/8
        this.emit('end')
    ))
    .pipe(renderbars({
      data: require('./src/index.coffee'),
    }))
    .pipe(prettify(indent_size: 2))
    .pipe(gulp.dest('build'))
    .pipe(if lr then require('gulp-livereload')(lr) else util.noop())

gulp.task 'html-build', html
gulp.task 'html-watch', ['html-build'], ->
  gulp.watch('src/html/**/*', ['html-build'])

#
# assets
#
imagemin = require('gulp-imagemin')
pngquant = require('imagemin-pngquant')

assetPaths = {
  "src/assets/**/*": "build"
  "node_modules/font-awesome/fonts/*": "build/fonts"
  "node_modules/bootstrap/dist/fonts/*": "build/fonts"
}

assets = (isWatch) ->
  ->
    imgFilter = filter("*.{png,gif,jpg,jpeg,svg}")

    _.each assetPaths, (to, from) ->
      gulp.src(from, dot: true)
        .pipe(if isWatch then require('gulp-watch')(from) else util.noop())
        .pipe(newer(to))
        # minify images
        #.pipe(imgFilter)
        #.pipe(imagemin(
        #  use: [pngquant()]
        #))
        #.pipe(imgFilter.restore())
        # end images minify
        .pipe(gulp.dest(to))
        .pipe(if lr then require('gulp-livereload')(lr) else util.noop())

gulp.task 'assets-build', assets(false)
gulp.task 'assets-watch', assets(true)

#
# server
#
connect = require('connect')
ecstatic = require('ecstatic')

server = (isWatch) ->
  (cb) ->
    app = connect()

    if isWatch
      app.use(require('connect-livereload')(
        port: env.LIVERELOAD_PORT or 35729
      ))

    app.use(ecstatic(
      root: __dirname + "/build"
      cache: env.CACHE or 0
      autoIndex: true
      showDir: true
    ))

    app.listen(env.PORT or 5000, cb)

gulp.task 'server', server(false)
gulp.task 'server-watch', server(true)

#
# livereload
#
livereload = (cb) ->
  lr = require('tiny-lr')()
  lr.listen(env.LIVERELOAD_PORT or 35729, cb)

gulp.task('livereload', livereload)

#
# deploy
#

gulp.task 'branch', ->
  branch = require('gulp-build-branch')
  branch(
    folder: 'build'
  )

gulp.task 'dokku', ->
  deploy = require('gulp-gh-pages')
  gulp.src('build/**/*', dot: true)
    .pipe(deploy("dokku@next.cobudget.co:app",
      origin: 'deploy'
      branch: 'awesome'
    ))

# prod tasks
gulp.task('build', ['js-build', 'css-build', 'html-build', 'assets-build'])
gulp.task('start', ['build', 'server'])
gulp.task('publish', ['build', 'branch'])

# dev tasks
gulp.task('watch', ['js-watch', 'css-watch', 'html-watch', 'assets-watch'])
gulp.task('develop', ['livereload', 'watch', 'server-watch'])

gulp.task('default', ['develop'])
