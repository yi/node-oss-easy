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

oss = null

TARGET_BUCKET = null

generateRandomId = ->
  return "#{(Math.random() * 36 >> 0).toString(36)}#{(Math.random() * 36 >> 0).toString(36)}#{Date.now().toString(36)}"

# init the oss client
# @param {String} key
# @param {String} secret
exports.init = (key, secret, bucketName) ->
  unless _.isString(key) and _.isString(secret) and _.isString(bucketName) and key.length > 0 and secret.length > 0 and bucketName.length > 0
    return throw new Error "Invalid arguments. key:#{key}, secret:#{secret}"

  oss = new ossAPI.OssClient
    accessKeyId: key
    accessKeySecret: secret

  return

# read file from oss
# @param {String} bucketName
# @param {String} filename
# @param {Object} [options] , refer to [options] of fs.readFile
# @param {Function} callback
exports.readFile = (filename, options, callback) ->
  return throw new Error "Please run oss-easy.init() first" unless oss?

  pathToTempFile = "/tmp/#{generateRandomId()}"

  args =
    bucket: TARGET_BUCKET
    object: filename
    dstFile: pathToTempFile

  callback = options if not callback? and _.isFunction(options)

  oss.getObject args, (err)->
    if err?
      callback(err)
    else
      fs.readFile pathToTempFile, options, callback

  return

# read file from oss
# @param {String} bucketName
# @param {String} filename
# @param {String | Buffer} data
# @param {Function} callback
exports.writeFile(filename, data, callback) ->
  return throw new Error "Please run oss-easy.init() first" unless oss?

  pathToTempFile = "/tmp/#{generateRandomId()}"

  fs.writeFile pathToTempFile, data, (err)->
    if err?
      return callback(err)
    else
      args =
        bucket: TARGET_BUCKET
        object: filename
        srcFile: pathToTempFile

      oss.putObject args, callback

  return



