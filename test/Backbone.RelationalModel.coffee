define (require) ->

  Backbone = require '../lib/backbone-relational-mapper'

  describe 'Backbone.RelationalModel', ->

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

    describe 'save()', ->

      it 'should save a new model', (done) ->
        collection = new @TestCollection
        collection.bind 'reset', ->
          nbModels = collection.length
          model = new @TestModel
            strField: 'TestModel'
          model.save()
          collection2 = new @TestCollection
          collection2.bind 'reset', ->
            expect(collection2.length).to.be.above nbModels
            done()
            #collection2.fetch()
        debugger
        collection.fetch()
