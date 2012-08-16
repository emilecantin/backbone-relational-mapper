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
          class @TestModel2 extends Backbone.RelationalModel
            fields:
              id: Backbone.Types.Primary
              strField: Backbone.Types.String
              intField: Backbone.Types.Integer
          TestModel2 = @TestModel2

          class @TestCollection extends Backbone.Collection
            model: TestModel2

          TestModel2 = @TestModel2
          testText = @testText = "text#{(new Date).getTime()}"
          tasks = []
          models = []
          for i in [0..9]
            do (i) ->
              models[i] = new TestModel2
              models[i].set
                strField: testText
                intField: i % 2
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
                  intField: 0
            collection.on 'reset', ->
              expect(collection.length).to.equal 5
              expect(collection.first().get 'intField').to.equal 0
              expect(collection.first().get 'strField').to.equal testText
              done()

        describe 'ORDER BY', ->

          it 'should return the models in ascending order', (done) ->
            testText = @testText
            collection = new @TestCollection
            collection.fetch
              db_params:
                order_by: '"intField"'
            collection.on 'reset', ->
              expect(collection.length).to.equal 10
              expect(collection.at(0).get 'intField').to.equal 0
              expect(collection.at(0).get 'strField').to.equal testText
              expect(collection.at(1).get 'intField').to.equal 0
              expect(collection.at(1).get 'strField').to.equal testText
              done()

          it 'should return the models in descending order', (done) ->
            testText = @testText
            collection = new @TestCollection
            collection.fetch
              db_params:
                order_by: '"intField" DESC'
            collection.on 'reset', ->
              expect(collection.length).to.equal 10
              expect(collection.at(0).get 'intField').to.equal 1
              expect(collection.at(0).get 'strField').to.equal testText
              expect(collection.at(1).get 'intField').to.equal 1
              expect(collection.at(1).get 'strField').to.equal testText
              done()

        describe 'LIMIT', ->

          it 'should limit the size of the returned result set', (done) ->
            testText = @testText
            collection = new @TestCollection
            collection.fetch
              db_params:
                where:
                  strField: testText
                  intField: 0
                limit: 3
                order_by: '"intField" DESC'
            collection.on 'reset', ->
              expect(collection.length).to.equal 3
              expect(collection.at(0).get 'intField').to.equal 0
              expect(collection.at(0).get 'strField').to.equal testText
              expect(collection.at(1).get 'intField').to.equal 0
              expect(collection.at(1).get 'strField').to.equal testText
              done()

        describe 'OFFSET', ->

          it 'should limit the size of the returned result set', (done) ->
            testText = @testText
            collection = new @TestCollection
            collection.fetch
              db_params:
                where:
                  strField: testText
                limit: 3
                offset: 4
                order_by: '"intField" ASC'
            collection.on 'reset', ->
              expect(collection.length).to.equal 3
              expect(collection.at(0).get 'intField').to.equal 0
              expect(collection.at(0).get 'strField').to.equal testText
              expect(collection.at(1).get 'intField').to.equal 1
              expect(collection.at(1).get 'strField').to.equal testText
              done()

