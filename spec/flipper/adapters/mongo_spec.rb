require 'helper'
require 'flipper/adapters/mongo'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Mongo do
  let(:collection) { Mongo::MongoClient.new.db('testing')['testing'] }

  subject { described_class.new(collection) }

  before do
    collection.remove
  end

  def read_key(key)
    if (doc = collection.find_one(:_id => key.to_s))
      value = doc['v']

      if value.is_a?(::Array)
        value = value.to_set
      end

      value
    end
  end

  def write_key(key, value)
    value = if value.is_a?(::Set)
      value.to_a.map(&:to_s)
    else
      value.to_s
    end

    criteria = {:_id => key.to_s}
    updates  = {'$set' => {'v' => value}}
    options  = {:upsert => true}
    collection.update criteria, updates, options
  end

  it_should_behave_like 'a flipper adapter'
end
