define (require) ->

  Backbone = require '../lib/backbone-relational-mapper'

  describe 'Backbone.DB.connect', ->

    before ->
      @pgConfig =
        dialect: 'postgres'
        host: '172.16.195.134'
        database: 'brm-test'
        user: 'brm-test'
        password: '53cr3t p455w0rd'

    it 'should throw an error if no config is specified', ->
      expect(Backbone.DB.connect).to.throw Error

    it 'should define Backbone.DB.getConnection', ->
      expect(Backbone.DB.getConnection).to.not.exist
      Backbone.DB.connect @pgConfig
      expect(Backbone.DB.getConnection).to.exist

    describe '"pg" dialect', ->

      describe 'Backbone.DB.getConnection', ->

        it 'should be able to connect via regular pg', (done) ->
          pg = require 'pg'
          pg.connect @pgConfig, (err, client) ->
            done err if err
            client.query("SELECT 'hello'", done)

        it 'should return a pg connection', (done) ->
          Backbone.DB.connect @pgConfig
          Backbone.DB.getConnection (err, client) ->
            done err if err
            client.query("SELECT 'hello'", done)

