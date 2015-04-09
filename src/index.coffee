ngClassify = require 'ng-classify'
path = require 'path'

createNgClassifyPreprocessor = (args, config = {}, logger, helper) ->

  log = logger.create 'preprocessor.ng-classify'
  defaultOptions = {}
  options = helper.merge defaultOptions, args.options or {}, config.options or {}

  transformPath = args.transformPath or config.transformPath or (filepath) ->
      file.path.replace(/\.coffee$/, '.js')

  (content, file, done) ->

    log.debug "Processing \"#{file.originalPath}\""
    file.path = transformPath file.originalPath

    opts = helper._.clone options

    try
      result = ngClassify content
    catch e
      log.error "${e.message}\n  at #{file.originalPath}:#{e.location.first_line}"
      return done e, null

    if result.v3SourceMap
      map = JSON.parse result.v3SourceMap
      map.sources[0] = path.basename file.originalPath
      map.sourcesContent = [content]
      map.file = path.basename file.path
      file.sourceMap = map
      datauri = "data:application/json;charset=utf-8;base64,#{new Buffer(JSON.stringify map).toString 'base64'}"
      done null, result.js + "\n//@ sourceMappingURL=#{datauri}\n"
    else
      done null, result.js or result

createNgClassifyPreprocessor.$inject = [ 'args', 'config.ngClassifyPreprocessor', 'logger', 'helper' ]

module.exports = 'preprocessor:ng-classify': [ 'factory', createNgClassifyPreprocessor ]