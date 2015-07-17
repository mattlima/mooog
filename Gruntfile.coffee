"use strict"




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
        files: 'src/**/*.litcoffee'
        tasks: ['clean','docco','coffee']

    clean: ['dist']

    coffee:
      coffee_to_js:
        options:
          bare: true
          sourceMap: true
        expand: true
        flatten: false
        src: ["src/*.litcoffee"]
        dest: 'dist'
        ext: ".js"

    docco:
      debug:
        src: ['src/**/*.litcoffee']
        options:
          output: 'docs/'


  ######### TASK DEFINITIONS #########


  # build, dev server, watch
  grunt.registerTask 'dev', [
    'clean'
    'docco'
    'coffee'
    'watch'
  ]


  grunt.registerTask 'default', ['dev']
