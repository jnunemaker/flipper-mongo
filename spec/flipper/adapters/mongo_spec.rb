require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Mongo do
  let(:collection) { Mongo::Connection.new.db('testing')['testing'] }
  let(:criteria)   { {:_id => id} }
  let(:id)         { 'flipper' }

  subject { Flipper::Adapters::Mongo.new(collection, :id => id) }

  before do
    collection.remove(criteria)
  end

  def read_key(key)
    if (doc = collection.find_one(criteria))
      value = doc[key]

      if value.is_a?(::Array)
        value = value.to_set
      end

      value
    end
  end

  def write_key(key, value)
    if value.is_a?(::Set)
      value = value.to_a
    end

    options = {:upsert => true}
    updates = {'$set' => {key => value}}
    collection.update criteria, updates, options
  end

  it_should_behave_like 'a flipper adapter'
end
