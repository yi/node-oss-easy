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
  # @param {String} targetBucket bucket name
  constructor: (ossOptions, @targetBucket) ->
    unless _.isString(ossOptions.accessKeyId) and _.isString(ossOptions.accessKeySecret) and _.isString(@targetBucket)
      throw new Error "missing input parameter: accessKeyId:#{ossOptions.accessKeyId}, accessKeySecret: #{ossOptions.accessKeySecret}, targetBucket:#{targetBucket}"
      return

    ossOptions['timeout'] = ossOptions['timeout'] || 5 * 60 * 1000
    @oss = new ossAPI.OssClient(ossOptions)

  # read file from oss
  # @param {String} bucketName
  # @param {String} filename
  # @param {Object} [options] , refer to [options] of fs.readFile
  # @param {Function} callback
  readFile : (filepath, options, callback) ->
    console.log "[oss-easy::readFile] #{filepath}"

    pathToTempFile = path.join "/tmp/", generateRandomId()

    @downloadFile filepath, pathToTempFile, (err) ->
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
  writeFile : (remoteFilePath, data, callback) ->
    console.log "[oss-easy::writeFile] #{filename}"

    if Buffer.isBuffer(data)
      contentType = "application/octet-stream"
    else
      contentType = "text/plain"
      data = new Buffer(data)


    args =
      bucket: @targetBucket
      object: remoteFilePath
      srcFile: data
      contentType : contentType

    @oss.putObject args, callback

    return

  # upload a local file to oss bucket
  # @param {String} remoteFilePath
  # @param {String} pathToFile
  # @param {Function} callback
  uploadFile : (remoteFilePath, pathToFile, callback) ->
    console.log "[oss-easy::uploadFile] #{pathToFile} -> #{remoteFilePath}"

    args =
      bucket: @targetBucket
      object: remoteFilePath
      srcFile: pathToFile

    @oss.putObject args, callback

    return

  # upload multiple files in a batch
  # @param {String[]} filenames, an array contain all filenames
  # @param {String} basePath[optional] if supplied, will path.join basePath, each filenames
  uploadFileBatch : (filenames, basePath, callback) ->
    unless Array.isArray filenames
      err = "bad argument, filenames:#{filenames}"
      console.error "[oss-easy::uploadFileBatch] #{err}"
      callback(err) if _.isFunction callback
      return

    if _.isFunction(basePath) and not callback?
      callback = basePath
      basePath = null

    if _.isString(basePath) and basePath.length > 0
      filenames = filenames.concat() # keep extenal input argument untouched
      for filename, i in filenames
        filenames[i] = path.join(basePath, filename)

    async.eachSeries filenames, (filename, eachCallback)=>
      @uploadFile path.basename(filename), filename, eachCallback
    , callback

    return

  # upload a local file to oss bucket
  # @param {String} filename
  # @param {String} pathToFile
  # @param {Function} callback
  downloadFile : (filename, pathToFile, callback) ->
    console.log "[oss-easy::downloadFile] #{pathToFile} <- #{filename}"

    args =
      bucket: @targetBucket
      object: filename
      dstFile: pathToFile

    @oss.getObject args, callback

    return

  # upload a local file to oss bucket
  # @param {String} filename
  # @param {String} basePath
  # @param {Function} callback
  downloadFileBatch : (filenames, basePath, callback) ->
    unless Array.isArray(filenames) and _.isString(basePath) and basePath.length > 0
      err = "bad argument, filenames:#{filenames}"
      console.error "[oss-easy::downloadFileBatch] #{err}"
      callback(err) if _.isFunction(callback)
      return

    async.eachSeries filenames, (filename, eachCallback)=>
      @downloadFile filename, path.join(basePath, filename), eachCallback
    , callback

    return

  # delete a single file from oss bucket
  # @param {String} filename
  deleteFile : (filename, callback) ->
    console.log "[oss-easy::deleteFile] #{filename}"

    args =
      bucket: @targetBucket
      object: filename

    @oss.deleteObject args, callback
    return

  # delete a single file from oss bucket
  # @param {String[]} filenames[]
  deleteFileBatch : (filenames, callback) ->
    unless Array.isArray filenames
      err = "bad argument, filenames:#{filenames}"
      console.error "[oss-easy::deleteFileBatch] #{err}"
      callback(err) if _.isFunction callback
      return
    async.eachSeries filenames, (filename, eachCallback)=>
      @deleteFile filename, eachCallback
    , callback

    return

module.exports=OssEasy



