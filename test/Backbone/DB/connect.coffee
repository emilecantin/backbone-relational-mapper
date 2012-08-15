define (require) ->

  Backbone = require '../../../lib'

  describe 'Backbone.DB.connect', ->

    it 'should throw an error if no config is specified', ->
      expect(Backbone.DB.connect).to.throw Error

    it 'should define Backbone.DB.getConnection', ->
      Backbone.DB.connect pgConfig
      expect(Backbone.DB.getConnection).to.exist

    describe '"pg" dialect', ->

      describe 'Backbone.DB.getConnection', ->

        it 'should be able to connect via regular pg', (done) ->
          pg = require 'pg'
          pg.connect pgConfig, (err, client) ->
            done err if err
            client.query("SELECT 'hello'", done)

        it 'should return a pg connection', (done) ->
          Backbone.DB.connect pgConfig
          Backbone.DB.getConnection (err, client) ->
            done err if err
            client.query("SELECT 'hello'", done)

        it 'should persist across calls to require', (done) ->
          OtherBackbone = require '../../../lib'
          OtherBackbone.DB.getConnection (err, client) ->
            done err if err
            client.query("SELECT 'hello'", done)
