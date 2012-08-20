#
# # Backbone-Relational-Mapper
#
define (require) ->

  Backbone = require 'backbone-relational'

  if window?
    throw new Error 'Just use the regular Backbone-Relational in the browser.'
  else

    Backbone.DB = require './Backbone/DB'

    Backbone.sync = require './Backbone/sync'

    # Possible types are presented here for convenience,
    # but you should use the strings in shared code
    Backbone.Types =
      String: 'STRING'
      Text: 'TEXT'
      Integer: 'INTEGER'
      Float: 'FLOAT'
      Date: 'DATE'
      Primary: 'PRIMARY'

  return Backbone
