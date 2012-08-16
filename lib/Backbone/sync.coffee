define (require) ->

  Backbone = require 'backbone-relational'
  inflection = require 'inflection'

  getTableData = (ModelClass, options={}) ->
    tablename = inflection.tableize ModelClass.name
    fields = []
    for name, definition of ModelClass::fields
      type = definition.type || definition
      unless name == 'id' and options.excludeId
        fields.push "\"#{name}\""
    return {
        tablename: tablename
        fields: fields
      }

  sync = (method, model, options={}) ->

    # Check which type of object we got
    if model instanceof Backbone.Collection
      collection = model
      ModelClass = collection.model
    else
      ModelClass = model.constructor

    placeholderIndex = 0
    values = []

    # Do the right thing according to the method
    switch method
      when 'create'
        Backbone.DB.getConnection (err, client) ->
          data = getTableData ModelClass,
            excludeId: true
            placeholderIndex: placeholderIndex
          sql = "INSERT INTO #{data.tablename}(#{data.fields}) VALUES (#{'$'+(++placeholderIndex) for i in [0..data.fields.length-1]})"
          for field of ModelClass::fields
            values.push model.get field unless field == 'id'
          query = client.query sql, values
          query.on 'end', ->
            model.trigger 'sync'
      when 'read'
        Backbone.DB.getConnection (err, client) ->
          data = getTableData ModelClass, excludeId: false
          if collection?
            collection.reset(null, silent: true) unless options.add
            sql = "SELECT #{data.fields} FROM #{data.tablename}"
            if options.db_params?
              # We have some options to add to the query
              if options.db_params.where?
                # It's a where clause
                whereConditions = []
                for key, value of options.db_params.where
                  whereConditions.push "\"#{key}\"=$#{++placeholderIndex}"
                  values.push value
                if whereConditions.length > 0
                  sql = "#{sql} WHERE #{whereConditions[0]}"
                  if whereConditions.length > 1
                    for i in [1..whereConditions.length-1]
                      sql = "#{sql} AND #{whereConditions[i]}"
            query = client.query sql, values
            query.on 'row', (row) ->
              collection.add row if collection?
            query.on 'end', ->
              collection.trigger 'reset' if collection?
          else
            throw new Error "Cannot fetch a model without its id!" unless (model.get 'id')?
            sql = "SELECT #{data.fields} FROM #{data.tablename} WHERE id=$#{++placeholderIndex} LIMIT 1"
            values.push model.get 'id'
            query = client.query sql, values
            query.on 'row', (row) ->
              model.set row
            query.on 'end', ->
              model.trigger 'sync'
      when 'update'
        Backbone.DB.getConnection (err, client) ->
          data = getTableData ModelClass, excludeId: true
          placeholders = []
          placeholders.push "#{data.fields[i]}=$#{++placeholderIndex}" for i in [0..data.fields.length-1]
          sql = "UPDATE #{data.tablename} SET #{placeholders} WHERE id=$#{++placeholderIndex}"
          for field of ModelClass::fields
            values.push model.get field unless field == 'id'
          values.push model.get 'id'
          query = client.query sql, values
          query.on 'end', ->
            model.trigger 'sync'
      when 'delete'
        data = getTableData ModelClass, excludeId: false
        Backbone.DB.getConnection (err, client) ->
          sql = "DELETE FROM #{data.tablename} WHERE id=$1"
          query = client.query sql, [model.get 'id']
          query.on 'end', ->
            model.trigger 'sync'
      else
        throw new Error "Unsupported method: #{method}"
