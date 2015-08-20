gulp = require 'gulp'
shelljs = require 'shelljs'

gulp.task 'run', (done) ->
  shelljs.exec 'sh -c "node node_modules/metacoffee/bin/metacoffee . test.meta.coffee && node test.meta.js"', -> do done


gulp.task 'default', ['run'], ->
  gulp.watch 'test.meta.coffee', ['run']
