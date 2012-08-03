require 'helper'
require 'flipper/adapters/mongo_with_ttl'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::MongoWithTTL do
  let(:collection) { Mongo::Connection.new.db('testing')['testing'] }
  let(:oid)        { BSON::ObjectId.new }
  let(:criteria)   { {:_id => oid} }

  subject { Flipper::Adapters::MongoWithTTL.new(collection, oid) }

  before do
    collection.remove(criteria)
  end

  it_should_behave_like 'a flipper adapter'

  it "can cache document in process for a number of seconds" do
    options = {:ttl => 10}
    adapter = Flipper::Adapters::MongoWithTTL.new(collection, oid, options)
    adapter.write('foo', 'bar')
    now = Time.now
    Timecop.freeze(now)

    collection.should_receive(:find_one).with(:_id => oid)
    adapter.read('foo')

    adapter.read('foo')
    adapter.read('bar')

    Timecop.travel(3)
    adapter.read('foo')

    Timecop.travel(6)
    adapter.read('foo')

    collection.should_receive(:find_one).with(:_id => oid)
    Timecop.travel(1)
    adapter.read('foo')

    Timecop.travel(4)
    adapter.read('foo')
  end
end
