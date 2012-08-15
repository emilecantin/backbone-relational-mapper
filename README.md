Backbone-Relational-Mapper
==========================

[![Build Status](https://secure.travis-ci.org/emilecantin/backbone-relational-mapper.png?branch=master)](http://travis-ci.org/emilecantin/backbone-relational-mapper)

Important note
--------------

This module is absolutely not ready for any usage, as it is in _very_ early development. Pull requests are welcome, but be aware that everything may change very fast; your relevant pull request today may not be relevant tomorrow.

Installation
------------

A simple `npm install backbone-relational-mapper` should do the trick. Open an issue if it doesn't.

You also need a database driver: `npm install pg` (the only supported database is Postgres at the moment).

Usage
-----

First you need to configure your database connection:

```coffee-script
Backbone.DB.connect
  dialect: 'postgres'
  host: 'localhost'
  database: 'my_database'
  user: 'my_user'
  password: 'my_password'
```

You should only need to do this once; it should persist across calls to `require()`.

Then, you should define your models as you would do in Backbone-Relational, with an added `fields` object:

    class SomeModel extends Backbone.RelationalModel

      fields:
        some_text_field: 'TEXT'
