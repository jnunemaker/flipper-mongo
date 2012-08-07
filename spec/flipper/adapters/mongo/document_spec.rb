require 'helper'
require 'flipper/adapters/mongo/document'

describe Flipper::Adapters::MongoSingleDocument::Document do
  subject          { described_class.new(collection, :id => id, :source => source) }
  let(:collection) { Mongo::Connection.new.db('testing')['testing'] }
  let(:id)         { described_class::DefaultId }
  let(:source)     { {} }
  let(:criteria)   { {:_id => id} }
  let(:options)    { {:safe => true, :upsert => true} }

  def document
    collection.find_one(criteria)
  end

  before do
    collection.remove(criteria)
  end

  it "defaults id to flipper" do
    described_class.new(collection).instance_variable_get("@id").should eq('flipper')
  end

  it "defaults id to flipper even if nil passed in for id" do
    described_class.new(collection, :id => nil).instance_variable_get("@id").should eq('flipper')
  end

  describe "loading document" do
    before do
      collection.update(criteria, {'$set' => {'foo' => 'bar', 'people' => [1, 2, 3]}}, options)
    end

    it "only happens once" do
      collection.should_receive(:find_one).with(criteria).once.and_return({})
      subject.read('foo')
      subject.set_members('people')
    end

    it "happens again if document is cleared" do
      collection.should_receive(:find_one).with(criteria)
      subject.read('foo')
      subject.set_members('people')

      subject.clear

      collection.should_receive(:find_one).with(criteria)
      subject.read('foo')
      subject.set_members('people')
    end
  end

  describe "#read" do
    context "existing key" do
      before do
        source['baz'] = 'wick'
        collection.update(criteria, {'$set' => {'foo' => 'bar'}}, options)
        @result = subject.read('foo')
      end

      it "returns value" do
        @result.should eq('bar')
      end

      it "clears and loads source hash" do
        source.should eq({
          '_id' => id,
          'foo' => 'bar',
        })
      end
    end

    context "missing key" do
      before do
        collection.update(criteria, {'$set' => {'foo' => 'bar'}}, options)
        @result = subject.read('apple')
      end

      it "returns nil" do
        @result.should be_nil
      end
    end

    context "missing document" do
      before do
        @result = subject.read('foo')
      end

      it "returns nil" do
        @result.should be_nil
      end
    end
  end

  describe "#write" do
    context "existing key" do
      before do
        collection.update(criteria, {'$set' => {'foo' => 'bar'}}, options)
        subject.write('foo', 'new value')
      end

      it "sets key" do
        document.fetch('foo').should eq('new value')
        source.fetch('foo').should eq('new value')
      end
    end

    context "missing key" do
      before do
        collection.update(criteria, {'$set' => {'foo' => 'bar'}}, options)
        subject.write('apple', 'orange')
      end

      it "sets key" do
        document.fetch('apple').should eq('orange')
        source.fetch('apple').should eq('orange')
      end
    end

    context "missing document" do
      before do
        subject.write('foo', 'bar')
      end

      it "creates document" do
        document.should_not be_nil
      end

      it "sets key" do
        document.fetch('foo').should eq('bar')
        source.fetch('foo').should eq('bar')
      end
    end
  end

  describe "#delete" do
    before do
      collection.update(criteria, {'$set' => {'foo' => 'bar', 'apple' => 'orange'}}, options)
      @result = subject.delete('foo')
    end

    it "removes the key" do
      document.key?('foo').should be_false
      source.key?('foo').should be_false
    end

    it "does not remove other keys" do
      document.fetch('apple').should eq('orange')
    end
  end

  describe "#set_members" do
    context "existing key" do
      before do
        collection.update(criteria, {'$set' => {'people' => [1, 2, 3], 'foo' => 'bar'}}, options)
        @result = subject.set_members('people')
      end

      it "returns set" do
        @result.should eq(Set[1, 2, 3])
      end

      it "loads source hash" do
        source.should eq({
          '_id'    => id,
          'people' => Set[1, 2, 3],
          'foo'    => 'bar',
        })
      end
    end

    context "missing key" do
      before do
        collection.update(criteria, {'$set' => {'people' => [1, 2, 3]}}, options)
        @result = subject.set_members('users')
      end

      it "returns empty set" do
        @result.should eq(Set.new)
      end
    end

    context "missing document" do
      it "returns empty set" do
        subject.set_members('people').should eq(Set.new)
      end
    end
  end

  describe "#set_add" do
    context "existing key" do
      before do
        collection.update(criteria, {'$set' => {'people' => [1, 2, 3]}}, options)
        subject.set_add('people', 4)
      end

      it "adds value to set" do
        document.fetch('people').should eq([1, 2, 3, 4])
        source.fetch('people').should eq(Set[1, 2, 3, 4])
      end
    end

    context "missing key" do
      before do
        collection.update(criteria, {'$set' => {'people' => [1, 2, 3]}}, options)
        subject.set_add('users', 1)
      end

      it "adds value to set" do
        document.fetch('users').should eq([1])
        source.fetch('users').should eq(Set[1])
      end
    end

    context "missing document" do
      before do
        subject.set_add('people', 1)
      end

      it "creates document" do
        document.should_not be_nil
      end

      it "adds value to set" do
        document.fetch('people').should eq([1])
        source.fetch('people').should eq(Set[1])
      end
    end
  end

  describe "#set_delete" do
    context "existing key" do
      before do
        collection.update(criteria, {'$set' => {'people' => [1, 2, 3]}}, options)
        subject.set_delete 'people', 3
      end

      it "removes value to key" do
        document.fetch('people').should eq([1, 2])
        source.fetch('people').should eq(Set[1, 2])
      end
    end

    context "missing key" do
      before do
        collection.update(criteria, {'$set' => {'people' => [1, 2, 3]}}, options)
      end

      it "does not error" do
        expect { subject.set_delete 'foo', 1 }.to_not raise_error
      end
    end

    context "missing document" do
      it "does not error" do
        expect { subject.set_delete 'foo', 1 }.to_not raise_error
      end
    end
  end

  describe "#clear" do
    before do
      collection.update(criteria, {'$set' => {'foo' => 'bar'}}, options)
      subject.read('foo') # load the source hash
      subject.clear
    end

    it "clears the source hash" do
      source.should be_empty
    end

    it "does not remove the document" do
      document.should_not be_empty
    end

    it "marks the document as not loaded" do
      subject.loaded?.should be_false
    end
  end
end
