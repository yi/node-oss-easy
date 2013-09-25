require 'mocha'
should = require('chai').should()
oss_easy = require "../oss-easy"
fs = require "fs"


STRING_CONTENT_FOR_TESTING = "just a piece of data"

STRING_CONTENT_FOR_TESTING2 = "222 just a piece of data 222"

#oss = oss_easy.init("T2ddFoapcbkps1S7", "0ByL2vqAnG17F4k6auJLiKd1kcu7xu", "testdrive")
oss = oss_easy.init("T2ddFoapcbkps1S7", "0ByL2vqAnG17F4k6auJLiKd1kcu7xu", "mocha-test")


FILE_NAMES= [
  "#{Date.now()}-t1",
  "#{Date.now()}-t2",
  "#{Date.now()}-t3",
  "#{Date.now()}-t4"]

describe "testing oss", (done)->

  it "writeFile and readFile should work", (done)->
    filename = "just-a-test"
    oss.writeFile filename, STRING_CONTENT_FOR_TESTING, (err)->
      #console.log err
      should.not.exist(err)
      oss.readFile filename, 'utf8', (err, data)->
        data.should.equal STRING_CONTENT_FOR_TESTING
        done()

  it "uploadFile and downloadFile should work", (done)->
    pathToTempFile = "/tmp/#{Date.now()}"
    pathToTempFile2 = "/tmp/#{Date.now()}-back"
    fs.writeFileSync pathToTempFile, STRING_CONTENT_FOR_TESTING2

    filename = "test-file-upload-download"

    oss.uploadFile filename, pathToTempFile, (err) ->
      should.not.exist(err)
      oss.downloadFile filename, pathToTempFile2, (err) ->
        should.not.exist(err)
        fs.readFileSync(pathToTempFile2, 'utf8').should.equal(fs.readFileSync(pathToTempFile, 'utf8'))
        done()

  it "uploadFile in a batch should work", (done)->
    for i in [0...4] by 1
      fs.writeFileSync "/tmp/#{FILE_NAMES[i]}", "#{STRING_CONTENT_FOR_TESTING2}-#{i}"

    oss.uploadFileBatch FILE_NAMES, "/tmp", (err)->
      should.not.exist(err)
      done()

  it "delete file should work", (done)->
    filename = "just-a-test"
    oss.deleteFile filename, (err)->
      should.not.exist(err)
      done()

  it "delete multiple files in a batch should work", (done)->
    filename = "just-a-test"
    oss.deleteFileBatch FILE_NAMES, (err)->
      should.not.exist(err)
      done()


