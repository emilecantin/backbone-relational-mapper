define (require) ->

  Backbone = require '../lib/backbone-relational-mapper'

  describe 'Backbone.Collection', ->

    before ->
      class @TestModel extends Backbone.RelationalModel
        fields:
          id: Backbone.Types.Primary
          strField: Backbone.Types.String
      TestModel = @TestModel

      class @TestCollection extends Backbone.Collection
        model: TestModel

    it 'should connect', (done) ->
      Backbone.DB.connect pgConfig
      done()

    describe 'fetch()', ->

      it 'should generate a SELECT statement', (done) ->
        collection = new @TestCollection
        collection.bind 'reset', ->
          expect(collection.length).to.be.above 1
          done()
        collection.fetch()
