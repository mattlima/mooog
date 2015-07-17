"use strict"





# # Globbing
# for performance reasons we're only matching one level down:
# 'test/spec/{,*/}*.js'
# use this if you want to recursively match all subfolders:
# 'test/spec/**/*.js'
module.exports = (grunt, options) ->
  pkg = grunt.file.readJSON('package.json')
  require('load-grunt-tasks') grunt

  options =
    paths: null # UNIMPLEMENTED




  ###### PLUGIN CONFIGURATIONS ######
  grunt.initConfig
    options: options

    pkg: pkg

    # grunt-contrib-watch
    watch:
      js:
        files: 'src/*.litcoffee'
        tasks: ['coffeeify:basic']

    clean:
      dist: ['dist']

    # coffeeify
    coffeeify:
      basic:
        options: {}
        files: [
            src: ['src/*.litcoffee', 'src/*.js']
            dest: 'dist/mooog.js'
        ]



  ######### TASK DEFINITIONS #########



  # build, dev server, watch
  grunt.registerTask 'dev', [
    'coffeeify'
    'watch'
  ]


  grunt.registerTask 'default', ['dev']
