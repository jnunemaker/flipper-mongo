require 'helper'
require 'flipper/adapters/mongo_with_ttl'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::MongoWithTTL do
  let(:collection) { Mongo::Connection.new.db('testing')['testing'] }
  let(:criteria)   { {:_id => id} }
  let(:id)         { described_class::DefaultId }

  subject { Flipper::Adapters::MongoWithTTL.new(collection) }

  before do
    collection.remove(criteria)
  end

  it_should_behave_like 'a flipper adapter'

  it "can cache document in process for a number of seconds" do
    options = {:ttl => 10}
    adapter = Flipper::Adapters::MongoWithTTL.new(collection, options)
    adapter.write('foo', 'bar')
    now = Time.now
    Timecop.freeze(now)

    collection.should_receive(:find_one).with(:_id => id)
    adapter.read('foo')

    adapter.read('foo')
    adapter.read('bar')

    Timecop.travel(3)
    adapter.read('foo')

    Timecop.travel(6)
    adapter.read('foo')

    collection.should_receive(:find_one).with(:_id => id)
    Timecop.travel(1)
    adapter.read('foo')

    Timecop.travel(4)
    adapter.read('foo')
  end
end
