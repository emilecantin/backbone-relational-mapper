Backbone-Relational-Mapper
==========================

[![Build Status](https://secure.travis-ci.org/emilecantin/backbone-relational-mapper.png?branch=master)](http://travis-ci.org/emilecantin/backbone-relational-mapper)

Important note
--------------

This module is absolutely not ready for any usage, as it is in _very_ early development. Pull requests are welcome, but be aware that everything may change very fast; your relevant pull request today may not be relevant tomorrow.

Installation
------------

A simple `npm install backbone-relational-mapper` should do the trick. Open an issue if it doesn't.

Usage
-----

You should define your models as you would do in Backbone-Relational, with an added `fields` object:

    class SomeModel extends Backbone.RelationalModel

      fields:
        some_text_field: Backbone.Types.Text
