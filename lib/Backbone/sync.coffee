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

  log = (sql, values) ->
    if Backbone.DB.logger? and typeof Backbone.DB.logger is 'function'
      Backbone.DB.logger sql
      Backbone.DB.logger values

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
          fields = []
          placeholders = []
          for field of ModelClass::fields
            unless field == 'id'
              fields.push "\"#{field}\""
              placeholders.push "$#{++placeholderIndex}"
              values.push model.get field
          sql = "INSERT INTO #{data.tablename}(#{fields}) VALUES (#{placeholders})"
          log sql, values
          query = client.query sql, values
          query.on 'end', ->
            model.trigger 'sync'
          query.on 'error', (err) ->
            model.trigger 'error', err
      when 'read'
        Backbone.DB.getConnection (err, client) ->
          data = getTableData ModelClass, excludeId: false
          if collection?
            collection.reset(null, silent: true) unless options.add
            sql = "SELECT * FROM #{data.tablename}"
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
              if options.db_params.order_by?
                sql = "#{sql} ORDER BY #{options.db_params.order_by}"
              if options.db_params.limit?
                sql = "#{sql} LIMIT $#{++placeholderIndex}"
                values.push options.db_params.limit
              if options.db_params.offset?
                sql = "#{sql} OFFSET $#{++placeholderIndex}"
                values.push options.db_params.offset
            log sql, values
            query = client.query sql, values
            query.on 'row', (row) ->
              collection.add row
            query.on 'end', ->
              collection.trigger 'reset'
            query.on 'error', (err) ->
              collection.trigger 'error', err
          else
            throw new Error "Cannot fetch a model without its id!" unless (model.get 'id')?
            sql = "SELECT * FROM #{data.tablename} WHERE id=$#{++placeholderIndex} LIMIT 1"
            values.push model.get 'id'
            log sql, values
            query = client.query sql, values
            query.on 'row', (row) ->
              model.set row
            query.on 'end', (result) ->
              if result.rowCount == 0
                model.trigger 'error', 'Not found'
              else if result.rowCount == 1
                model.trigger 'sync'
              else
                model.trigger 'error', 'Too many results'
            query.on 'error', (err) ->
              model.trigger 'error', err
      when 'update'
        Backbone.DB.getConnection (err, client) ->
          data = getTableData ModelClass, excludeId: true
          placeholders = []
          for field of ModelClass::fields
            unless field == 'id'
              placeholders.push "\"#{field}\"=$#{++placeholderIndex}"
              values.push model.get field
          sql = "UPDATE #{data.tablename} SET #{placeholders} WHERE id=$#{++placeholderIndex}"
          values.push model.get 'id'
          log sql, values
          query = client.query sql, values
          query.on 'end', ->
            model.trigger 'sync'
          query.on 'error', (err) ->
            model.trigger 'error', err
      when 'delete'
        data = getTableData ModelClass, excludeId: false
        Backbone.DB.getConnection (err, client) ->
          sql = "DELETE FROM #{data.tablename} WHERE id=$#{++placeholderIndex}"
          values.push model.get 'id'
          log sql, values
          query = client.query sql, values
          query.on 'end', ->
            model.trigger 'sync'
          query.on 'error', (err) ->
            model.trigger 'error', err
      else
        throw new Error "Unsupported method: #{method}"
