define (require) ->

  Backbone = require '../lib/backbone-relational-mapper'

  describe 'Backbone.DB.connect', ->

    it 'should throw an error if no config is specified', ->
      expect(Backbone.DB.connect).to.throw Error

    it 'should define Backbone.DB.getConnection', ->
      expect(Backbone.DB.getConnection).to.not.exist
      Backbone.DB.connect
        dialect: 'postgres'
        host: 'localhost'
        database: 'brm-test'
        user: 'brm-test'
        password: '53cr3t p455w0rd'
      expect(Backbone.DB.getConnection).to.exist

    describe '"pg" dialect', ->

      describe 'Backbone.DB.getConnection', ->

        it 'should return a pg connection', (done) ->

