define (require)->

  Backbone = require '../lib/backbone-relational-mapper'

  describe 'Backbone.sync', ->

    before ->
      class @TestModel extends Backbone.RelationalModel

      class @TestCollection extends Backbone.Collection

    it 'should be some test', ->
      test = new @TestModel
      test.save()
      collection = new @TestCollection
      collection.fetch()
      expect(true).to.be.true
