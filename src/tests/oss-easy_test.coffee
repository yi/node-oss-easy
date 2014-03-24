require 'mocha'
should = require('chai').should()
ossEasy = require "../oss-easy"
fs = require "fs"
path = require "path"
config = require "./config"


STRING_CONTENT_FOR_TESTING = "just a piece of data"

STRING_CONTENT_FOR_TESTING2 = "222 just a piece of data 222"

ossOptions =
  accessKeyId : config.accessKeyId
  accessKeySecret : config.accessKeySecret
  bucket : config.bucket
  uploaderHeaders :
    "Content-disposition" : "attachment;filename=whatever.gif"

oss = new ossEasy(ossOptions)

FILE_NAMES= [
  "#{Date.now()}-t1",
  "#{Date.now()}-t2",
  "#{Date.now()}-t3",
  "#{Date.now()}-t4"]

describe "testing oss", (done)->

  @timeout(10000)

  it "writeFile and readFile", (done)->
    filename = "just/a/test"
    oss.writeFile filename, STRING_CONTENT_FOR_TESTING, (err)->
      #console.log err
      should.not.exist(err)
      oss.readFile filename, 'utf8', (err, data)->
        data.should.equal STRING_CONTENT_FOR_TESTING
        done()


  it "uploadFile and downloadFile", (done)->
    pathToTempFile = "/tmp/#{Date.now()}"
    pathToTempFile2 = "/tmp/#{Date.now()}-back"
    fs.writeFileSync pathToTempFile, STRING_CONTENT_FOR_TESTING2

    filename = "test-file-upload-download"

    oss.uploadFile pathToTempFile, filename, (err) ->
      should.not.exist(err)
      oss.downloadFile filename, pathToTempFile2, (err) ->
        should.not.exist(err)
        fs.readFileSync(pathToTempFile2, 'utf8').should.equal(fs.readFileSync(pathToTempFile, 'utf8'))
        done()


  it "uploadFile file with custom header", (done)->
    pathToTempFile = "/tmp/#{Date.now()}-custom-header"
    fs.writeFileSync pathToTempFile, STRING_CONTENT_FOR_TESTING2

    filename = "test-file-upload-custom-header"

    oss.uploadFile pathToTempFile, filename,
      "Cache-Control": "max-age=5"
      "Expires" : Date.now() + 300000
    , (err) ->
      should.not.exist(err)
      done()
      return


  it "uploadFile multiple files", (done)->
    tasks = {}

    for i in [0...4] by 1
      tasks["/tmp/#{FILE_NAMES[i]}"] = "test/upload/multiple/files-#{i}"
      fs.writeFileSync "/tmp/#{FILE_NAMES[i]}", "#{STRING_CONTENT_FOR_TESTING2}-#{i}"

    oss.uploadFiles tasks, (err)->
      should.not.exist(err)
      done()
      return
    return


  it "download multiple files", (done)->
    tasks = {}
    for i in [0...4] by 1
      tasks["test/upload/multiple/files-#{i}"] = "/tmp/download-#{FILE_NAMES[i]}"

    oss.downloadFiles tasks, (err)->
      should.not.exist(err)

      for i in [0...4] by 1
        fs.readFileSync("/tmp/download-#{FILE_NAMES[i]}", 'utf8').should.equal(fs.readFileSync("/tmp/#{FILE_NAMES[i]}", 'utf8'))

      done()
      return

  it "delete file", (done)->
    remoteFilePath = "just/a/test"
    oss.deleteFile remoteFilePath, (err)->
      should.not.exist(err)
      done()
      return
    return


  it "delete a folder", (done)->
    oss.deleteFolder "test/upload/multiple/", (err)->
      should.not.exist(err)
      done()
      return
    return

