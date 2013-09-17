require 'mocha'
should = require('chai').should()
oss = require "../oss-easy"


STRING_CONTENT_FOR_TESTING = "just a piece of data"


describe "this is a test", (done)->
  before ()->
    oss.init("T2ddFoapcbkps1S7", "0ByL2vqAnG17F4k6auJLiKd1kcu7xu", "testdrive")

  it "should be ok", ->
    filename = "just-a-test"
    oss.writeFile filename, STRING_CONTENT_FOR_TESTING, (err)->
      should.not.exist(err)
      oss.readFile filename, 'utf8', (err, data)->
        data.should.equal STRING_CONTENT_FOR_TESTING

