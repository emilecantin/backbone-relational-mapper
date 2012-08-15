define (require) ->

  Backbone = require '../../lib'

  describe 'Simple Backbone.RelationalModel', ->

    describe 'basic operations:', ->

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

        it 'should save an existing model', (done) ->
          TestCollection = @TestCollection
          TestModel = @TestModel
          collection = new TestCollection
          collection.fetch()
          collection.on 'reset', ->
            model = collection.last()
            model.set strField: 'NewValue'
            model.save()
            model.on 'sync', ->
              collection2 = new TestCollection
              collection2.fetch()
              collection2.on 'reset', ->
                model2 = collection2.last()
                expect(model2.get 'strField').to.equal 'NewValue'
                done()

      describe 'destroy()', ->

        it 'should delete the model', (done) ->
          TestCollection = @TestCollection
          TestModel = @TestModel
          collection = new TestCollection
          collection.fetch()
          collection.on 'reset', ->
            nbModels = collection.length
            model = collection.first()
            model.destroy()
            model.on 'sync', ->
              collection2 = new TestCollection
              collection2.fetch()
              collection2.on 'reset', ->
                expect(collection2.length).to.be.below nbModels
                done()

      describe 'fetch()', ->

        it 'should fetch the model', (done) ->
          model = new @TestModel
          model.set id: 2
          model.fetch()
          model.on 'sync', ->
            expect(model.get 'strField').to.equal 'TEST2'
            done()

#    describe 'search conditions:', ->
#
#      before ->
#        class @TestModel extends Backbone.RelationalModel
#          fields:
#            id: Backbone.Types.Primary
#            strField: Backbone.Types.String
#        TestModel = @TestModel
#
#        class @TestCollection extends Backbone.Collection
#          model: TestModel
#
#      it 'should return the right models', (done) ->
#        collection = new @TestCollection
#        testText = "text#{(new Date).getTime()}"
#        for i in [0..9]
#          model = new @TestModel
#          model.save strField: testText
#        # Wait for the last model to save before continuing
#        model.on 'sync', ->
#          collection.fetch
#            db_params:
#              where:
#                strField: testText
#          collection.on 'reset', ->
#            expect(collection.length).to.equal 10
#            done()
