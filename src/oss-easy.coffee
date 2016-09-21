##
# oss-easy
# https://github.com/yi/node-oss-easy
#
# Copyright (c) 2013 yi
# Licensed under the MIT license.
##

_ = require "underscore"
ossAPI = require 'oss-client'
fs = require "fs"
async = require "async"
path = require "path"
debuglog = require("debug")("oss-easy")
assert = require "assert"
wget = require('node-wget')
UrlParser = require 'url'

generateRandomId = ->
  return "#{(Math.random() * 36 >> 0).toString(36)}#{(Math.random() * 36 >> 0).toString(36)}#{Date.now().toString(36)}"

NOT_PASSABLE_HEAD_FIELS = [
  'content-Length'
  'age'
  'accept-ranges'
  'connection'
  'etag'
]


NONSENCE_CALLBACK = ()->

class OssEasy

  # constructor function
  # @param {Object} ossOptions
  #   accessKeyId :
  #   accessKeySecret :
  #   host : default: 'oss.aliyuncs.com';
  #   port : default:  '8080';
  #   timeout : default: 300000 ms;
  #   uploaderHeaders : http headers for all uploading actions
  #   bucket : target bucket
  # @param {String} targetBucket bucket name
  constructor: (ossOptions, targetBucket) ->

    assert ossOptions, "missing options"
    assert ossOptions.accessKeyId, "missing oss key id"
    assert ossOptions.accessKeySecret, "missing access secret"

    @targetBucket = targetBucket || ossOptions.bucket

    assert @targetBucket, "missing bucket name"

    ossOptions['timeout'] = ossOptions['timeout'] || 5 * 60 * 1000
    ossOptions.port or= 80

    if ossOptions.uploaderHeaders?
      @uploaderHeaders = ossOptions.uploaderHeaders
      @contentType = @uploaderHeaders.contentType if @uploaderHeaders.contentType
      delete ossOptions['uploaderHeaders']

    debuglog "[constructor] bucket: %j, ossOptions:%j", @targetBucket, ossOptions

    @oss = new ossAPI.OssClient(ossOptions)


  # read file from oss
  # @param {String} bucketName
  # @param {String} filename
  # @param {Object} [options] , refer to [options] of fs.readFile
  # @param {Function} callback
  readFile : (remoteFilePath, options, callback) ->
    debuglog "[readFile] #{remoteFilePath}"

    pathToTempFile = path.join "/tmp/", generateRandomId()

    @downloadFile remoteFilePath, pathToTempFile, (err) ->
      if err?
        callback(err) if _.isFunction callback
      else
        fs.readFile pathToTempFile, options, callback

    return

  # write data to oss
  # @param {String} bucketName
  # @param {String} filename
  # @param {String | Buffer} data
  # @param {Function} callback
  writeFile : (remoteFilePath, data, headers, callback) ->
    debuglog "[writeFile] #{remoteFilePath}"

    if Buffer.isBuffer(data)
      contentType = "application/octet-stream"
    else
      contentType = "text/plain"
      data = new Buffer(data)

    if _.isFunction(headers) and not callback?
      callback = headers
      headers = null

    args =
      bucket: @targetBucket
      object: remoteFilePath
      srcFile: data
      contentType : (headers and headers.contentType) || @contentType || contentType

    headers = _.extend({}, headers, @uploaderHeaders) if headers? or @uploaderHeaders?
    args["userMetas"] = headers if headers?

    @oss.putObject args, callback

    return

  # upload a local file to oss bucket
  # @param {String} remoteFilePath
  # @param {String} localFilePath
  # @param {Function} callback
  uploadFile : (filePath, remoteFilePath, headers, callback) ->

    if _.isFunction(headers) and not callback?
      callback = headers
      headers = null

    filePath = String(filePath || '')
    isLocal = (filePath.indexOf('http://') isnt 0) and (filePath.indexOf('https://') isnt 0)
    if isLocal
      unless fs.existsSync(filePath)
        return callback?("file not found. #{filePath}")
      return @_uploadFileLocal(filePath, remoteFilePath, headers, callback)

    # transport remote file

    pathToTempFile = path.join "/tmp/", generateRandomId()

    options =
      url:filePath
      dest: pathToTempFile
      timeout: 60 *1000

    wget options, (err, response)=>
      return callback?(err) if err?

      #headers = _.extend({}, response.headers, headers)

      arr = []
      for key, value of response.headers
        if key.toLowerCase() is "content-type"
          contentType = value

      #for key in arr
        #delete headers[key]

      #debuglog "[uploadFile] remote headers", headers

      if contentType
        headers = {'content-type': contentType}

      @_uploadFileLocal(pathToTempFile, remoteFilePath, headers, callback)
      return
    return


  _uploadFileLocal : (localFilePath, remoteFilePath, headers, callback) ->
    debuglog "[_uploadFileLocal] local:#{localFilePath} -> #{@targetBucket}:#{remoteFilePath}"

    timeKey = "[oss-easy::_uploadFileLocal] -> #{remoteFilePath}"
    console.time timeKey

    if _.isFunction(headers) and not callback?
      callback = headers
      headers = null

    args =
      bucket: @targetBucket
      object: remoteFilePath
      srcFile: localFilePath
      contentType : @contentType

    headers = _.extend({}, headers, @uploaderHeaders) if headers? or @uploaderHeaders?
    args["userMetas"] = headers if headers?

    @oss.putObject args, (err)->
      debuglog "[_uploadFileLocal] callback err:", err
      console.timeEnd timeKey
      callback err
      return
    return


  # transport a remote file from url to oss bucket
  transport : (url, remoteFilePath, headers, callback)->
    debuglog "[transport] url:#{url} -> #{@targetBucket}:#{remoteFilePath}"

    pathToTempFile = path.join "/tmp/", generateRandomId()

    options =
      url:url
      dest: pathToTempFile
      timeout: 60 *1000

    wget options, (err)=>
      return callback?(err) if err?
      @uploadFile(pathToTempFile, remoteFilePath, headers, callback)
      return
    return

  # upload multiple files in a batch
  # @param {Object KV} tasks
  #   keys: localFilePaths
  #   values: remoteFilePaths
  # @param {Function} callback
  uploadFiles : (tasks, headers,  callback) ->
    debuglog "[uploadFiles] tasks:%j", tasks

    if _.isFunction(headers) and not callback?
      callback = headers
      headers = null

    callback or= NONSENCE_CALLBACK

    unless tasks?
      err = "bad argument, tasks:#{tasks}"
      console.error "ERROR [oss-easy::uploadFiles] #{err}"
      return callback(err)

    localFilePaths = _.keys(tasks)

    async.eachSeries localFilePaths, (localFilePath, eachCallback)=>
      @uploadFile localFilePath, tasks[localFilePath], headers, eachCallback
    , callback

    return

  # upload a local file to oss bucket
  # @param {String} remoteFilePath
  # @param {String} localFilePath
  # @param {Function} callback
  downloadFile : (remoteFilePath, localFilePath, callback=NONSENCE_CALLBACK) ->
    debuglog "[downloadFile] #{@targetBucket}:#{remoteFilePath} -> local:#{localFilePath}"

    args =
      bucket: @targetBucket
      object: remoteFilePath
      dstFile: localFilePath

    @oss.getObject args, callback

    return

  # upload a local file to oss bucket
  # @param {Object KV} tasks
  #   keys: remoteFilePaths
  #   values: localFilePaths
  # @param {Function} callback
  downloadFiles: (tasks, callback=NONSENCE_CALLBACK) ->
    unless tasks?
      err = "bad argument, tasks:#{tasks}"
      console.error "[oss-easy::downloadFileBatch] #{err}"
      callback(err) if _.isFunction(callback)
      return

    remoteFilePaths = _.keys(tasks)

    async.eachSeries remoteFilePaths, (remoteFilePath, eachCallback)=>
      @downloadFile remoteFilePath, tasks[remoteFilePath], eachCallback
    , callback

    return

  # delete a single file from oss bucket
  # @param {String} remoteFilePath
  deleteFile : (remoteFilePath, callback=NONSENCE_CALLBACK) ->
    debuglog "[deleteFile] #{remoteFilePath}"

    unless _.isString(remoteFilePath) and remoteFilePath
      err = "bad argument, remoteFilePath:#{remoteFilePath}"
      callback(err) if _.isFunction callback
      return

    args =
      bucket: @targetBucket
      object: remoteFilePath

    @oss.deleteObject args, callback
    return

  # delete a list of single files from oss bucket
  # @param {String[]} remoteFilePaths[]
  deleteFiles: (remoteFilePaths, callback=NONSENCE_CALLBACK) ->
    debuglog "[deleteFiles] #{remoteFilePaths}"

    unless Array.isArray(remoteFilePaths) and remoteFilePaths.length
      err = "bad argument, remoteFilePaths:#{remoteFilePaths}"
      debuglog "[deleteFileBatch] #{err}"
      callback(err) if _.isFunction callback
      return

    async.eachSeries remoteFilePaths, (remoteFilePath, eachCallback)=>
      @deleteFile remoteFilePath, eachCallback
    , callback

    return

  # delete all files under the given remote folder
  # @param {String} remoteFolderPath
  deleteFolder : (remoteFolderPath, callback=NONSENCE_CALLBACK) ->
    debuglog "[deleteFolder] #{remoteFolderPath}"

    unless _.isString(remoteFolderPath) and remoteFolderPath
      err = "bad argument, remoteFolderPath:#{remoteFolderPath}"
      debuglog "ERROR [deleteFolder] error:#{err}"
      callback(err)
      return

    # list folder
    args =
      bucket: @targetBucket
      prefix : remoteFolderPath
      delimiter : "/"

    @oss.listObject args, (err, result)=>
      if err?
        debuglog "ERROR [deleteFolder] error:#{err}"
        callback(err)
        return
      #console.dir result.ListBucketResult.Contents
      filelist = []
      try
        for item in result.ListBucketResult.Contents
          key = item.Key
          filelist.push(if Array.isArray(key) then key[0] else key)
      catch err
        debuglog "ERROR [deleteFolder] error:#{err}"
        callback(err)
        return

      @deleteFiles filelist, callback

      return
    return

  copyFile : (sourceFilePath, destinationFilePath, callback) ->
    debuglog "[copyFile] #{@targetBucket}:#{sourceFilePath} -> destinationFilePath:#{destinationFilePath}"
    #console.log "[copyFile] #{@targetBucket}:#{sourceFilePath} -> destinationFilePath:#{destinationFilePath}"
    args =
      bucket: @targetBucket
      object: destinationFilePath
      srcObject: sourceFilePath
    @oss.copyObject args, (err) ->
      callback err
      return
    return

  copyFiles : (tasks, callback) ->
    debuglog "[copyFile] tasks:%j", tasks
    assert _.isFunction(callback),"missing callback"
    unless tasks?
      err = "bad argument, tasks:#{tasks}"
      console.error "[oss-easy::copyFiles] #{err}"
      callback(err) if _.isFunction(callback)
      return
    sourceFilePaths = _.keys(tasks)
    async.eachSeries sourceFilePaths, (sourceFilePath, eachCallback) =>
      @copyFile sourceFilePath, tasks[sourceFilePath], eachCallback
    , callback
    return

  #复制一个目录下的文件到另一个目录
  copyFolder: (sourceFolderPath, destinationFolderPath, callback) ->
    debuglog "[copyFolder] source:#{sourceFolderPath} destination:#{destinationFolderPath}"
    unless _.isString(sourceFolderPath) and sourceFolderPath and destinationFolderPath and _.isString(destinationFolderPath)
      err = "bad argument, source:#{sourceFolderPath} destination:#{destinationFolderPath}"
      debuglog "ERROR [copyFolder] error:#{err}"
      callback(err)
      return
    # list folder
    args =
      bucket: @targetBucket
      prefix : sourceFolderPath
      delimiter : "/"

    @oss.listObject args, (err, result)=>
      if err?
        debuglog "ERROR [copyFolder] error:#{err}"
        callback(err)
        return

      #console.dir result.ListBucketResult.Contents
      tasks = {}
      try
        for item in result.ListBucketResult.Contents
          key = item.Key
          des = path.join "#{destinationFolderPath}", path.basename(key)
          tasks[key] = des
      catch err
        debuglog "ERROR [copyFolder] error:#{err}"
        callback(err)
        return
      #console.dir tasks
      @copyFiles tasks, callback
      return
    return

  setUploaderHeaders: (uploaderHeaders) -> @uploaderHeaders = uploaderHeaders

  setContentType: (contentType) -> @contentType = contentType


module.exports=OssEasy



