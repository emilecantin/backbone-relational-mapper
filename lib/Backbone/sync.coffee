define (require) ->

  Backbone = require 'backbone-relational'
  inflection = require 'inflection'

  getTableData = (ModelClass, options={}) ->
    tablename = inflection.tableize ModelClass.name
    fields = []
    placeholders = []
    placeholderIndex = 1
    for name, definition of ModelClass::fields
      type = definition.type || definition
      unless name == 'id' and options.excludeId
        fields.push "\"#{name}\""
        placeholders.push "$#{placeholderIndex}"
        placeholderIndex = placeholderIndex + 1
    return {
        tablename: tablename
        fields: fields
        placeholders: placeholders
        placeholderIndex: placeholderIndex
      }

  sync = (method, model, options={}) ->

    # Check which type of object we got
    if model instanceof Backbone.Collection
      collection = model
      ModelClass = collection.model
    else
      ModelClass = model.constructor

    # Get useful data from the model's class

    # Do the right thing according to the method
    switch method
      when 'create'
        Backbone.DB.getConnection (err, client) ->
          data = getTableData ModelClass, excludeId: true
          sql = "INSERT INTO #{data.tablename}(#{data.fields}) VALUES (#{data.placeholders})"
          values = []
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
            query = client.query sql
            query.on 'row', (row) ->
              collection.add row if collection?
            query.on 'end', ->
              collection.trigger 'reset' if collection?
          else
            throw new Error "Cannot fetch a model without its id!" unless (model.get 'id')?
            sql = "SELECT #{data.fields} FROM #{data.tablename} WHERE id=$1 LIMIT 1"
            query = client.query sql, [model.get 'id']
            query.on 'row', (row) ->
              model.set row
            query.on 'end', ->
              model.trigger 'sync'
      when 'update'
        Backbone.DB.getConnection (err, client) ->
          data = getTableData ModelClass, excludeId: true
          placeholders = []
          placeholders.push "#{data.fields[i]}=#{data.placeholders[i]}" for i in [0..data.fields.length-1]
          sql = "UPDATE #{data.tablename} SET #{placeholders} WHERE id=$#{i+1}"
          values = []
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
