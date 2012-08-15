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

    Backbone.Types =
      String: 'STRING'
      Text: 'TEXT'
      Integer: 'INTEGER'
      Float: 'FLOAT'
      Primary: 'PRIMARY'

  return Backbone
