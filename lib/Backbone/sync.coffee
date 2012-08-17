define (require) ->

  Backbone = require 'backbone-relational'
  inflection = require 'inflection'

  getTableData = (ModelClass, options={}) ->
    tablename = inflection.tableize ModelClass.name
    fields =
      withoutId: []
      withId: []
    for name, definition of ModelClass::fields
      type = definition.type || definition
      if not options.include_all and definition.includeInJSON?
        if not definition.includeInJSON
        else
          fields.withoutId.push "\"#{name}\"" unless name == 'id'
          fields.withId.push "\"#{name}\""
      else
        fields.withoutId.push "\"#{name}\"" unless name == 'id'
        fields.withId.push "\"#{name}\""
    return {
        tablename: tablename
        fields: fields
      }

  log = (sql, values) ->
    if Backbone.DB.logger? and typeof Backbone.DB.logger is 'function'
      Backbone.DB.logger sql
      Backbone.DB.logger values

  sync = (method, object, options={}) ->
    options.db_params = {} unless options.db_params?
    placeholderIndex = 0
    values = []

    if object instanceof Backbone.Collection
      collection = object
      ModelClass = collection.model
    else if object instanceof Backbone.RelationalModel
      model = object
      ModelClass = model.constructor
    else
      throw new Error "Unsupported object: #{object}"

    data = getTableData ModelClass,
      placeholderIndex: placeholderIndex
      include_all: options.db_params.include_all

    Backbone.DB.getConnection (err, client) ->
      # Check which type of object we got
      if collection?
        switch method
          when 'read'
            collection.reset(null, silent: true) unless options.add
            sql = "SELECT #{data.fields.withId} FROM #{data.tablename}"
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
            query.on 'error', (err) ->
              collection.trigger 'error', err
            query.on 'row', (row) ->
              collection.add row
            query.on 'end', ->
              collection.trigger 'reset'
              collection.trigger 'sync'
          else
            throw new Error "Unsupported method: #{method}"
      else if model?
        switch method
          when 'create'
            fields = []
            placeholders = []
            for field of ModelClass::fields
              unless field == 'id'
                fields.push "\"#{field}\""
                placeholders.push "$#{++placeholderIndex}"
                values.push model.get field
            fields.push "\"createdAt\""
            placeholders.push "$#{++placeholderIndex}"
            values.push new Date()
            fields.push "\"updatedAt\""
            placeholders.push "$#{++placeholderIndex}"
            values.push new Date()
            sql = "INSERT INTO #{data.tablename}(#{fields}) VALUES (#{placeholders}) RETURNING *"
            log sql, values
            query = client.query sql, values, (err, result) ->
              if err
                model.trigger 'error', err
              else
                model.set result.rows[0]
                model.trigger 'sync'

          when 'read'
            throw new Error "Cannot fetch a model without its id!" unless (model.get 'id')?
            sql = "SELECT #{data.fields.withId} FROM #{data.tablename} WHERE id=$#{++placeholderIndex} LIMIT 1"
            values.push model.get 'id'
            log sql, values
            query = client.query sql, values, (err, result) ->
              if err
                model.trigger 'error', err
              else
                if result.rowCount == 0
                  model.trigger 'error', 'Not found'
                else if result.rowCount == 1
                  model.set result.rows[0]
                  model.trigger 'sync'
                else
                  model.trigger 'error', 'Too many results'

          when 'update'
            placeholders = []
            for field of ModelClass::fields
              unless field == 'id'
                placeholders.push "\"#{field}\"=$#{++placeholderIndex}"
                values.push model.get field
            placeholders.push "\"updatedAt\"=$#{++placeholderIndex}"
            values.push new Date
            sql = "UPDATE #{data.tablename} SET #{placeholders} WHERE id=$#{++placeholderIndex} RETURNING *"
            values.push model.get 'id'
            log sql, values
            query = client.query sql, values, (err, result) ->
              if err
                model.trigger 'error', err
              else
                model.set result.rows[0]
                model.trigger 'sync'

          when 'delete'
            sql = "DELETE FROM #{data.tablename} WHERE id=$#{++placeholderIndex}"
            values.push model.get 'id'
            log sql, values
            query = client.query sql, values, (err, result) ->
              if err
                model.trigger 'error', err
              else
                model.trigger 'sync'
          else
            throw new Error "Unsupported method: #{method}"
