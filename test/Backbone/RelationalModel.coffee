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

        it 'should set a new model\'s id', (done) ->
          TestModel = @TestModel
          model = new TestModel
            strField: 'TestModel With ID'
          model.save()
          model.on 'error', done
          model.on 'sync', ->
            expect(model.get 'id').to.not.equal undefined
            model2 = TestModel.findOrCreate id: model.get 'id'
            model2.off()
            model2.fetch()
            model2.on 'error', done
            model2.on 'sync', ->
              expect(model.get 'strField').to.equal model2.get 'strField'
              done()

        it 'should save an existing model', (done) ->
          TestModel = @TestModel
          model = TestModel.findOrCreate id: 2
          model.off()
          model.fetch()
          model.on 'sync', ->
            model.off 'sync'
            model.set strField: 'NewValue'
            model.save()
            model.on 'error', done
            model.on 'sync', ->
              expect(model.get 'strField').to.equal 'NewValue'
              model2 = TestModel.findOrCreate id: 2
              model2.off()
              model2.fetch()
              model2.on 'error', done
              model2.on 'sync', ->
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
          model.set id: 3
          model.fetch()
          model.on 'sync', ->
            expect(model.get 'strField').to.equal 'TEST3'
            done()

        it 'should not fetch a non-existent model', (done) ->
          model = new @TestModel
          model.set id: 3423
          model.fetch()
          model.on 'sync', ->
            done 'Should not be called'
          model.on 'error', (err) ->
            expect(err).to.equal 'Not found'
            done()

      describe 'include fields', ->

        before ->
          class @TestModel3 extends Backbone.RelationalModel
            fields:
              id: Backbone.Types.Primary
              intField: Backbone.Types.Integer
              strField: Backbone.Types.String
              strFieldExclude:
                type: Backbone.Types.String
                includeInJSON: false

        it 'should not include values that are marked as "includeInJSON: false"', (done) ->
          model = @TestModel3.findOrCreate id: 1
          model.off()
          model.fetch()
          model.on 'error', done
          model.on 'sync', ->
            expect(model.get 'intField').to.equal 3
            expect(model.get 'strField').to.equal 'TEST3'
            expect(model.get 'nonExistentField').to.equal undefined
            expect(model.get 'strFieldExclude').to.equal undefined
            done()

        it 'should include values that are marked as "includeInJSON: true"', (done) ->
          model = @TestModel3.findOrCreate id: 1
          model.off()
          model.fetch()
          model.on 'error', done
          model.on 'sync', ->
            expect(model.get 'intField').to.equal 3
            expect(model.get 'strField').to.equal 'TEST3'
            expect(model.get 'nonExistentField').to.equal undefined
            expect(model.get 'strFieldExclude').to.equal undefined
            done()

        it 'should include values that are marked as "includeInJSON: false" if forced', (done) ->
          model = @TestModel3.findOrCreate id: 1
          model.off()
          model.fetch
            db_params:
              include_all: true
          model.on 'error', done
          model.on 'sync', ->
            expect(model.get 'intField').to.equal 3
            expect(model.get 'strField').to.equal 'TEST3'
            expect(model.get 'nonExistentField').to.equal undefined
            expect(model.get 'strFieldExclude').to.equal "INVISIBLE VALUE"
            done()
