#
# # Backbone-Relational-Mapper
#
define (require) ->

  Backbone = require 'backbone-relational'
  inflection = require 'inflection'

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

      # Check which type of object we got
      if model instanceof Backbone.Collection
        collection = model
        ModelClass = collection.model
      else
        ModelClass = model.constructor

      # Get useful data from the model's class
      fields = []
      for name, definition of ModelClass::fields
        type = definition.type || definition
        fields.push "\"#{name}\""
      tablename = inflection.tableize ModelClass.name

      # Do the right thing according to the method
      switch method
        when 'create'
          Backbone.DB.getConnection (err, client) ->
            # Remove the 'id' attribute
            indexOfId = fields.indexOf 'id'
            fields = fields.splice indexOfId
            placeholders = []
            placeholders.push "$#{i}" for i in [1..fields.length]
            sql = "INSERT INTO #{tablename}(#{fields}) VALUES (#{placeholders})"
            values = []
            for field of ModelClass::fields
              values.push model.get field unless field == 'id'
            query = client.query sql, values
            query.on 'end', ->
              model.trigger 'sync'
        when 'read'
          Backbone.DB.getConnection (err, client) ->
            sql = "SELECT #{fields} FROM #{tablename}"
            query = client.query sql
            query.on 'row', (row) ->
              collection.add row if collection?
            query.on 'end', ->
              collection.trigger 'reset' if collection?
        when 'update'
          Backbone.DB.getConnection (err, client) ->
            indexOfId = fields.indexOf 'id'
            fields = fields.splice indexOfId
            placeholders = []
            placeholders.push "#{fields[i]}=$#{i}" for i in [1..fields.length]
            sql = "UPDATE #{tablename} SET #{placeholders}"
            console.log sql
        else
          throw new Error "Unsupported method: #{method}"

    Backbone.Types =
      String: 'STRING'
      Text: 'TEXT'
      Integer: 'INTEGER'
      Float: 'FLOAT'
      Primary: 'PRIMARY'

  return Backbone
