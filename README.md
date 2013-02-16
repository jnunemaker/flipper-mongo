# Flipper Mongo

A [MongoDB](https://github.com/mongodb/mongo-ruby-driver) adapter for [Flipper](https://github.com/jnunemaker/flipper).

## Usage

```ruby
require 'flipper/adapters/mongo'
collection = Mongo::MongoClient.new.db('testing')['flipper']
adapter = Flipper::Adapters::Mongo.new(collection)
flipper = Flipper.new(adapter)
# profit...
```

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-mongo'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-mongo


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
