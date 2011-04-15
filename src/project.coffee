fs = require('fs')
sys = require('sys')
yaml = require("#{root}/lib/yaml")
Path = require("path")
Glob = require("glob").globSync
_ = require("#{root}/lib/underscore")

String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.substring(1).toLowerCase()

class Project
  constructor: (cwd) ->
    @cwd = cwd
    @root = cwd
    @yaml = yaml.eval(fs.readFileSync(@configPath()) + "")

  name : ->
    @cwd.replace(/.+\//,'')

  language : ->
    'coffee' # or 'js'
    
  configPath : ->
    Path.join(@cwd, "config.yml")
    
  getScriptTagFor: (path) ->
    if path.match(/coffee$/)
      "<script src='#{path}' type='text/coffeescript'></script>"
    else
      "<script src='#{path}' type='text/javascript'></script>"
      
  getStyleTagFor: (path) ->
    if path.match(/less$/)
  	  "<link href='#{path}' rel='stylesheet/less' type='text/css' />"
    else
  	  "<link href='#{path}' media='screen' rel='stylesheet' type='text/css' />"

  testScriptIncludes: ->
    tags = for path in Glob(Path.join(@cwd, "test", "**", "*.#{@language()}"))
      script = path.replace(@cwd, '')
      @getScriptTagFor script
      
    tags.join("\n")

  getFilesToWatch : ->
    result = @getScriptDependencies()
    result.push 'index.jst'
    result
    
  getScriptDependencies : ->
    scripts = _([])

    for pathspec in @yaml.javascripts
      for path in Glob(Path.join(@cwd, pathspec))
        path = path.replace(@cwd, '').replace(/^[.\/]+/,'/')
        scripts.push path
        
    scripts.value()
    
  getDependencies: (section) ->
    result = _([])

    for pathspec in @yaml[section]
      for path in Glob(Path.join(@cwd, pathspec))
        path = path.replace(@cwd, '').replace(/^[.\/]+/,'/')
        result.push path

    result.value()

  getStylesheetDependencies : ->
    result = []

    for pathspec in @yaml.stylesheets
      for path in Glob(Path.join(@cwd, pathspec))
        path = path.replace(@cwd, '')
        result.push path
        
    result
    
  stylesheetIncludes : ->
    tags = for css in @getStylesheetDependencies()
      @getStyleTagFor css
      
    tags.join("\n")
    
  specIncludes : ->
    tags = for script in @getScriptDependencies()
      @getScriptTagFor script
      
    for script in @getDependencies('specs')
      tags.push @getScriptTagFor script
    
    tags.join("\n")

  scriptIncludes : ->
    tags = for script in @getScriptDependencies()
      @getScriptTagFor script
      
    tags.join("\n")
    

exports.Project = Project