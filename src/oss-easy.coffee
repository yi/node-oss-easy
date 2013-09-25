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

  constructor: (key, secret, @targetBucket) ->
    @oss = new ossAPI.OssClient
      accessKeyId: key
      accessKeySecret: secret


  # read file from oss
  # @param {String} bucketName
  # @param {String} filename
  # @param {Object} [options] , refer to [options] of fs.readFile
  # @param {Function} callback
  readFile : (filename, options, callback) ->
    pathToTempFile = "/tmp/#{generateRandomId()}"

    #console.log "pathToTempFile:#{pathToTempFile}"
    #args =
      #bucket: @targetBucket
      #object: filename
      #dstFile: pathToTempFile

    #callback = options if not callback? and _.isFunction(options)

    #oss.getObject args, (err)->

    @downloadFile filename, pathToTempFile, (err) ->
      if err?
        callback(err)
      else
        fs.readFile pathToTempFile, options, callback

    return

  # write data to oss
  # @param {String} bucketName
  # @param {String} filename
  # @param {String | Buffer} data
  # @param {Function} callback
  writeFile : (filename, data, callback) ->
    pathToTempFile = "/tmp/#{generateRandomId()}"

    fs.writeFile pathToTempFile, data, (err)=>
      if err?
        return callback(err)
      else
        @uploadFile filename, pathToTempFile, callback
        #args =
          #bucket: TARGET_BUCKET
          #object: filename
          #srcFile: pathToTempFile

        #oss.putObject args, callback

    return

  # upload a local file to oss bucket
  # @param {String} filename
  # @param {String} pathToFile
  # @param {Function} callback
  uploadFile : (filename, pathToFile, callback) ->
    args =
      bucket: @targetBucket
      object: filename
      srcFile: pathToFile

    @oss.putObject args, callback

    return

  # upload multiple files in a batch
  uploadFileBatch : (filenames, basePath, callback) ->
    unless Array.isArray filenames
      err = "bad argument, filenames:#{filenames}"
      console.error "[oss-easy::uploadFilesd] #{err}"
      callback(err)
      return
    async.eachSeries filenames, (filename, eachCallback)=>
      @uploadFile filename, path.join(basePath, filename), eachCallback
    , callback

    return

  # upload a local file to oss bucket
  # @param {String} filename
  # @param {String} pathToFile
  # @param {Function} callback
  downloadFile : (filename, pathToFile, callback) ->
    args =
      bucket: @targetBucket
      object: filename
      dstFile: pathToFile

    @oss.getObject args, callback

    return

  # delete a single file from oss bucket
  # @param {String} filename
  deleteFile : (filename, callback) ->
    args =
      bucket: @targetBucket
      object: filename

    @oss.deleteObject args, callback
    return

  # delete a single file from oss bucket
  # @param {String} filename
  deleteFileBatch : (filenames, callback) ->
    unless Array.isArray filenames
      err = "bad argument, filenames:#{filenames}"
      console.error "[oss-easy::deleteFileBatch] #{err}"
      callback(err)
      return
    async.eachSeries filenames, (filename, eachCallback)=>
      @deleteFile filename, eachCallback
    , callback

    return

# init the oss client
# @param {String} key
# @param {String} secret
exports.init = (key, secret, bucketName) ->
  unless _.isString(key) and _.isString(secret) and _.isString(bucketName) and key.length > 0 and secret.length > 0 and bucketName.length > 0
    return throw new Error "Invalid arguments. key:#{key}, secret:#{secret}, bucket:#{bucketName}"

  return new OssEasy(key, secret, bucketName)

