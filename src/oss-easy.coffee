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

generateRandomId = ->
  return "#{(Math.random() * 36 >> 0).toString(36)}#{(Math.random() * 36 >> 0).toString(36)}#{Date.now().toString(36)}"

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
    if ossOptions.uploaderHeaders?
      @uploaderHeaders = ossOptions.uploaderHeaders
      delete ossOptions['uploaderHeaders']

    debuglog "[constructor] bucket: %j, ossOptions:%j", @targetBucket, ossOptions

    @oss = new ossAPI.OssClient(ossOptions)


  # read file from oss
  # @param {String} bucketName
  # @param {String} filename
  # @param {Object} [options] , refer to [options] of fs.readFile
  # @param {Function} callback
  readFile : (remoteFilePath, options, callback) ->
    debuglog "[oss-easy::readFile] #{remoteFilePath}"

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
    debuglog "[oss-easy::writeFile] #{remoteFilePath}"

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
      contentType : contentType

    headers = _.extend({}, headers, @uploaderHeaders) if headers? or @uploaderHeaders?
    args["userMetas"] = headers if headers?

    @oss.putObject args, callback

    return

  # upload a local file to oss bucket
  # @param {String} remoteFilePath
  # @param {String} localFilePath
  # @param {Function} callback
  uploadFile : (localFilePath, remoteFilePath, headers, callback) ->
    debuglog "[uploadFile] local:#{localFilePath} -> #{@targetBucket}:#{remoteFilePath}"

    if _.isFunction(headers) and not callback?
      callback = headers
      headers = null

    args =
      bucket: @targetBucket
      object: remoteFilePath
      srcFile: localFilePath

    headers = _.extend({}, headers, @uploaderHeaders) if headers? or @uploaderHeaders?
    args["userMetas"] = headers if headers?

    debuglog "[uploadFile] headers:%j", headers
    @oss.putObject args, callback

    return

  # upload multiple files in a batch
  # @param {Object KV} tasks
  #   keys: localFilePaths
  #   values: remoteFilePaths
  # @param {Function} callback
  uploadFiles : (tasks, headers,  callback) ->
    debuglog "[uploadFiles] tasks:%j", tasks
    unless tasks?
      err = "bad argument, tasks:#{tasks}"
      console.error "[oss-easy::uploadFiles] #{err}"
      callback(err) if _.isFunction(callback)
      return

    if _.isFunction(headers) and not callback?
      callback = headers
      headers = null

    localFilePaths = _.keys(tasks)

    async.eachSeries localFilePaths, (localFilePath, eachCallback)=>
      @uploadFile localFilePath, tasks[localFilePath], headers, eachCallback
    , callback

    return

  # upload a local file to oss bucket
  # @param {String} remoteFilePath
  # @param {String} localFilePath
  # @param {Function} callback
  downloadFile : (remoteFilePath, localFilePath, callback) ->
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
  downloadFiles: (tasks, callback) ->
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
  deleteFile : (remoteFilePath, callback) ->
    debuglog "[oss-easy::deleteFile] #{remoteFilePath}"

    args =
      bucket: @targetBucket
      object: remoteFilePath

    @oss.deleteObject args, callback
    return

  # delete a single file from oss bucket
  # @param {String[]} remoteFilePaths[]
  deleteFiles: (remoteFilePaths, callback) ->
    unless Array.isArray remoteFilePaths
      err = "bad argument, remoteFilePaths:#{remoteFilePaths}"
      console.error "[oss-easy::deleteFileBatch] #{err}"
      callback(err) if _.isFunction callback
      return
    async.eachSeries remoteFilePaths, (remoteFilePath, eachCallback)=>
      @deleteFile remoteFilePath, eachCallback
    , callback

    return

module.exports=OssEasy



