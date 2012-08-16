define (require) ->

  Backbone = require '../../lib'
  async = require 'async'

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

      it 'should generate a "add" event for each row', (done) ->
        collection = new @TestCollection
        collection.on 'add', (model) ->
          expect(model.get "strField").to.be.a 'string'
        collection.on 'reset', ->
          done()
        collection.fetch()

      it 'should generate a "reset" event', (done) ->
        collection = new @TestCollection
        collection.on 'reset', ->
          expect(collection.length).to.be.above 1
          done()
        collection.fetch()

      describe 'with search conditions:', ->

        before (done) ->
          class @TestModel extends Backbone.RelationalModel
            fields:
              id: Backbone.Types.Primary
              strField: Backbone.Types.String
          TestModel = @TestModel

          class @TestCollection extends Backbone.Collection
            model: TestModel

          TestModel = @TestModel
          testText = @testText = "text#{(new Date).getTime()}"
          tasks = []
          models = []
          for i in [0..9]
            do (i) ->
              models[i] = new TestModel
              models[i].set strField: testText
              tasks.push (cb) -> models[i].save(); models[i].on 'sync', -> cb()
          async.parallel tasks, (err, result) ->
            done()

        describe 'simple where', ->

          it 'should return the right models', (done) ->
            testText = @testText
            collection = new @TestCollection
            collection.fetch
              db_params:
                where:
                  strField: testText
            collection.on 'reset', ->
              expect(collection.length).to.equal 10
              done()

        describe 'composite where', ->

          it 'should return the right models', (done) ->
            testText = @testText
            collection = new @TestCollection
            collection.fetch
              db_params:
                where:
                  strField: testText
                  id: 12
            collection.on 'reset', ->
              expect(collection.length).to.equal 1
              expect(collection.first().get 'id').to.equal 12
              expect(collection.first().get 'strField').to.equal testText
              done()
