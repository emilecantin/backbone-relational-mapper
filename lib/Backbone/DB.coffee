define (require) ->

  Backbone = require 'backbone-relational'

  if Backbone.DB
    return Backbone.DB
  else
    DB =
      connect: (config) ->
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
    return DB
