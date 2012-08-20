define (require) ->

  Backbone = require 'backbone-relational'
  inflection = require 'inflection'
  async = require 'async'

  getTableData = (ModelClass, model, options={}) ->
    results =
      tablename: inflection.tableize ModelClass.name
      placeholderIndex: 0 || options.placeholderIndex
      fields: []
      fields_no_id: []
      values: []
      pairs: []
      placeholders: []

    for name, definition of ModelClass::fields
      type = definition.type || definition
      if options.include_all or not (definition.includeInJSON? and not definition.includeInJSON)
        results.fields.push "\"#{name}\""
        if options.update
          unless name == 'id'
            results.pairs.push "\"#{name}\"=$#{++results.placeholderIndex}"
            results.values.push model.get name
        else if options.create
          unless name == 'id'
            results.fields_no_id.push "\"#{name}\""
            results.values.push model.get name
            results.placeholders.push "$#{++results.placeholderIndex}"
    return results

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

    Backbone.DB.getConnection (err, client) ->
      # Check which type of object we got
      if collection?
        switch method
          when 'read'
            data = getTableData ModelClass, null,
              placeholderIndex: placeholderIndex
              include_all: options.db_params.include_all

            collection.reset(null, silent: true) unless options.add
            sql = "SELECT #{data.fields} FROM #{data.tablename}"
            if options.db_params.where?
              # It's a where clause
              whereConditions = []
              for key, value of options.db_params.where
                if value instanceof Array
                  placeholders = []
                  for item in value
                    placeholders.push "$#{++data.placeholderIndex}"
                    values.push item
                  whereConditions.push "\"#{key}\" IN (#{placeholders})"
                else
                  whereConditions.push "\"#{key}\"=$#{++data.placeholderIndex}"
                  values.push value
              if whereConditions.length > 0
                sql = "#{sql} WHERE #{whereConditions[0]}"
                if whereConditions.length > 1
                  for i in [1..whereConditions.length-1]
                    sql = "#{sql} AND #{whereConditions[i]}"
            if options.db_params.order_by?
              sql = "#{sql} ORDER BY #{options.db_params.order_by}"
            if options.db_params.limit?
              sql = "#{sql} LIMIT $#{++data.placeholderIndex}"
              values.push options.db_params.limit
            if options.db_params.offset?
              sql = "#{sql} OFFSET $#{++data.placeholderIndex}"
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
            data = getTableData ModelClass, model,
              placeholderIndex: placeholderIndex
              include_all: options.db_params.include_all
              create: true

            data.fields_no_id.push "\"createdAt\""
            data.placeholders.push "$#{++data.placeholderIndex}"
            data.values.push new Date()

            data.fields_no_id.push "\"updatedAt\""
            data.placeholders.push "$#{++data.placeholderIndex}"
            data.values.push new Date()

            # Handle relations
            if ModelClass::relations
              for relation in ModelClass::relations
                if model.get(relation.key) instanceof Backbone.RelationalModel
                  if model.get(relation.key).isNew()
                    throw new Error "You need to save #{relation.key} first!"
                  else
                    data.fields.push "\"#{relation.key}Id\""
                    data.fields_no_id.push "\"#{relation.key}Id\""
                    data.values.push model.get(relation.key).get 'id'
                    data.placeholders.push "$#{++data.placeholderIndex}"

            sql = "INSERT INTO #{data.tablename}(#{data.fields_no_id}) VALUES (#{data.placeholders}) RETURNING #{data.fields}"
            log sql, values
            query = client.query sql, data.values, (err, result) ->
              if err
                model.trigger 'error', err
              else
                model.set result.rows[0]
                model.trigger 'sync'

          when 'read'
            throw new Error "Cannot fetch a model without its id!" unless (model.get 'id')?

            data = getTableData ModelClass, model,
              placeholderIndex: placeholderIndex
              include_all: options.db_params.include_all

            # Handle relations
            if ModelClass::relations
              for relation in ModelClass::relations
                if relation.type == Backbone.HasOne
                  data.fields.push "\"#{relation.key}Id\""
            sql = "SELECT #{data.fields} FROM #{data.tablename} WHERE id=$#{++data.placeholderIndex} LIMIT 1"
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
                  # Fetch related models
                  related_models_tasks = []
                  if ModelClass::relations
                    for relation in ModelClass::relations
                      if relation.type == Backbone.HasOne
                        if relation.includeInJSON
                          if relation.includeInJSON instanceof Array or relation.includeInJSON instanceof String
                            fields = relation.includeInJSON
                          sql = "SELECT #{data.fields} FROM #{data.tablename} WHERE id=$#{++data.placeholderIndex} LIMIT 1"
                  model.trigger 'sync'
                else
                  model.trigger 'error', 'Too many results'

          when 'update'
            data = getTableData ModelClass, model,
              placeholderIndex: placeholderIndex
              include_all: options.db_params.include_all
              update: true

            data.pairs.push "\"updatedAt\"=$#{++data.placeholderIndex}"
            data.values.push new Date

            sql = "UPDATE #{data.tablename} SET #{data.pairs} WHERE id=$#{++data.placeholderIndex} RETURNING #{data.fields}"
            data.values.push model.get 'id'
            log sql, data.values
            query = client.query sql, data.values, (err, result) ->
              if err
                model.trigger 'error', err
              else
                model.set result.rows[0]
                model.trigger 'sync'

          when 'delete'
            data = getTableData ModelClass, model,
              placeholderIndex: placeholderIndex
              include_all: options.db_params.include_all
            sql = "DELETE FROM #{data.tablename} WHERE id=$#{++data.placeholderIndex}"
            values.push model.get 'id'
            log sql, values
            query = client.query sql, values, (err, result) ->
              if err
                model.trigger 'error', err
              else
                model.trigger 'sync'
          else
            throw new Error "Unsupported method: #{method}"
