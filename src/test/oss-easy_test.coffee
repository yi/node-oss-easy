require 'mocha'
should = require('chai').should()
oss = require "../oss-easy"


STRING_CONTENT_FOR_TESTING = "just a piece of data"


describe "testing oss", (done)->
  before ()->
    oss.init("T2ddFoapcbkps1S7", "0ByL2vqAnG17F4k6auJLiKd1kcu7xu", "testdrive")

  it "writeFile and readFile should work", (done)->
    filename = "just-a-test"
    oss.writeFile filename, STRING_CONTENT_FOR_TESTING, (err)->
      #console.log err
      should.not.exist(err)
      oss.readFile filename, 'utf8', (err, data)->
        data.should.equal STRING_CONTENT_FOR_TESTING
        done()

