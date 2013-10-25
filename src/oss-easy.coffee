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
    console.log "[oss-easy::readFile] #{filename}"

    pathToTempFile = path.join "/tmp/", generateRandomId()

    @downloadFile filename, pathToTempFile, (err) ->
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
  writeFile : (filename, data, callback) ->
    console.log "[oss-easy::writeFile] #{filename}"

    pathToTempFile = path.join "/tmp/", generateRandomId()

    fs.writeFile pathToTempFile, data, (err)=>
      if err?
        return callback(err) if _.isFunction callback
      else
        @uploadFile filename, pathToTempFile, callback
    return

  # upload a local file to oss bucket
  # @param {String} filename
  # @param {String} pathToFile
  # @param {Function} callback
  uploadFile : (filename, pathToFile, callback) ->
    console.log "[oss-easy::uploadFile] #{pathToFile} -> #{filename}"

    args =
      bucket: @targetBucket
      object: filename
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
  # @param {String} filename
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

# init the oss client
# @param {String} key
# @param {String} secret
exports.init = (key, secret, bucketName) ->
  unless _.isString(key) and _.isString(secret) and _.isString(bucketName) and key.length > 0 and secret.length > 0 and bucketName.length > 0
    return throw new Error "Invalid arguments. key:#{key}, secret:#{secret}, bucket:#{bucketName}"

  return new OssEasy(key, secret, bucketName)

