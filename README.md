Backbone-Relational-Mapper
==========================

Installation
------------

A simple `npm install backbone-relational-mapper` should do the trick. Open an issue if it doesn't.

Usage
-----

You should define your models as you would do in Backbone-Relational, with an added `fields` object:

    class SomeModel extends Backbone.RelationalModel

      fields:
        some_text_field: Backbone.Types.Text
