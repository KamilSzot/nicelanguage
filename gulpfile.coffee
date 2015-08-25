gulp = require 'gulp'
shelljs = require 'shelljs'

source = if process.argv[3] then process.argv[3].substr(2) else 'test'

gulp.task 'run', (done) ->
  shelljs.exec 'sh -c "node node_modules/metacoffee/bin/metacoffee . '+source+'.meta.coffee && node '+source+'.meta.js"', -> do done


gulp.task 'default', ['run'], ->
  gulp.watch source+'.meta.coffee', ['run']
