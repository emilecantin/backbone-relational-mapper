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
        TestCollection = @TestCollection
        TestModel = @TestModel
        collection = new TestCollection
        collection.fetch()
        collection.on 'reset', ->
          nbModels = collection.length
          model = new TestModel
            strField: 'TestModel'
          model.save()
          model.on 'sync', ->
            collection2 = new TestCollection
            collection2.fetch()
            collection2.on 'reset', ->
              expect(collection2.length).to.be.above nbModels
              done()

#      it 'should save an existing model', (done) ->
#        TestCollection = @TestCollection
#        TestModel = @TestModel
#        collection = new TestCollection
#        collection.on 'reset', ->
#          model = collection.last()
#          model.set strField: 'NewValue'
#          model.save()
#          model.on 'sync', ->
#            collection2 = new TestCollection
#            collection2.fetch()
#            collection2.on 'reset', ->
#              model2 = collection2.last()
#              expect(model2.get 'strField').to.equal 'NewValue'
#              done()
