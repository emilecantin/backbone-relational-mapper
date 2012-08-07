#
# # Backbone-Relational-Mapper
#
define (require) ->

  Backbone = require 'backbone-relational'

  if window?
    console.warn 'Just use the regular Backbone-Relational in the browser.'
  else

    Backbone.DB = {} || Backbone.DB
    Backbone.DB.connect = (config) ->
      # Some validation
      throw new Error 'Backbone.DB.connect() needs a config object' unless config
      @dialect = 'pg' || config.dialect

      # Now establish the connection
      switch @dialect
        when 'pg', 'postgres'
          pg = require 'pg'
          Backbone.DB.getConnection = (callback) ->
            pg.connect config, callback
        else
          throw new Error "Unsupported dialect: #{@dialect}"



    Backbone.sync = (method, model, options) ->
      test = 'test'

  return Backbone
