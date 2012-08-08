require 'helper'
require 'flipper/adapters/mongo_single_document'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::MongoSingleDocument do
  let(:collection) { Mongo::Connection.new.db('testing')['testing'] }
  let(:criteria)   { {:_id => id} }
  let(:id)         { 'flipper' }

  subject { described_class.new(collection, :id => id) }

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

  context "with cache" do
    before do
      subject.document_cache = true
    end

    it_should_behave_like 'a flipper adapter'

    it "should only query mongo once until reloaded" do
      collection.should_receive(:find_one).with(criteria).once.and_return({})
      subject.read('foo')
      subject.read('foo')
      subject.read('foo')
      subject.set_members('users')

      subject.reset_document_cache

      collection.should_receive(:find_one).with(criteria).once.and_return({})
      subject.read('foo')
      subject.read('foo')
      subject.set_members('users')
    end
  end

  context "without cache" do
    before do
      subject.document_cache = false
    end

    it_should_behave_like 'a flipper adapter'
  end

  describe "#use_document_cache" do
    it "turns cache on for block and restores to original after block" do
      subject.using_document_cache?.should be_false
      subject.use_document_cache do
        subject.using_document_cache?.should be_true
      end
      subject.using_document_cache?.should be_false
    end
  end

  describe "#document_cache=" do
    it "sets document cache" do
      subject.document_cache = true
      subject.using_document_cache?.should be_true

      subject.document_cache = false
      subject.using_document_cache?.should be_false
    end

    it "resets cached document" do
      subject.should_receive(:reset_document_cache)
      subject.document_cache = true
    end
  end
end
