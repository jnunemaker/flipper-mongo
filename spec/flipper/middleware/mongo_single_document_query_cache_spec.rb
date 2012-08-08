require 'helper'
require 'rack/test'
require 'flipper/middleware/mongo_single_document_query_cache'

describe Flipper::Middleware::MongoSingleDocumentQueryCache do
  include Rack::Test::Methods

  let(:collection) { Mongo::Connection.new.db('testing')['testing'] }
  let(:adapter)    { Flipper::Adapters::MongoSingleDocument.new(collection) }
  let(:flipper)    { Flipper.new(adapter) }

  class Enum < Struct.new(:iter)
    def each(&b)
      iter.call(&b)
    end
  end

  let(:app) {
    # ensure scoped for builder block, annoying...
    instance = adapter
    middleware = described_class

    Rack::Builder.new do
      use middleware, instance

      map "/" do
        run lambda {|env| [200, {}, []] }
      end

      map "/fail" do
        run lambda {|env| raise "FAIL!" }
      end
    end.to_app
  }

  it "delegates" do
    called = false
    app = lambda { |env|
      called = true
      [200, {}, nil]
    }
    middleware = described_class.new app, adapter
    middleware.call({})
    called.should be_true
  end

  it "enables document cache during delegation" do
    app = lambda { |env|
      adapter.using_document_cache?.should be_true
      [200, {}, nil]
    }
    middleware = described_class.new app, adapter
    middleware.call({})
  end

  it "enables document cache for body each" do
    app = lambda { |env|
      [200, {}, Enum.new(lambda { |&b|
        adapter.using_document_cache?.should be_true
        b.call "hello"
      })]
    }
    middleware = described_class.new app, adapter
    body = middleware.call({}).last
    body.each { |x| x.should eql('hello') }
  end

  it "disables document cache after body close" do
    app = lambda { |env| [200, {}, []] }
    middleware = described_class.new app, adapter
    body = middleware.call({}).last

    adapter.using_document_cache?.should be_true
    body.close
    adapter.using_document_cache?.should be_false
  end

  it "clears document cache after body close" do
    app = lambda { |env| [200, {}, []] }
    middleware = described_class.new app, adapter
    body = middleware.call({}).last
    adapter.write('hello', 'world')

    adapter.instance_variable_get("@document").should_not be_nil
    body.close
    adapter.instance_variable_get("@document").should be_nil
  end

  it "really does cache" do
    flipper[:stats].enable

    collection.should_receive(:find_one).once.and_return({})

    app = lambda { |env|
      flipper[:stats].enabled?
      flipper[:stats].enabled?
      flipper[:stats].enabled?
      flipper[:stats].enabled?
      flipper[:stats].enabled?
      flipper[:stats].enabled?

      [200, {}, []]
    }
    middleware = described_class.new app, adapter
    middleware.call({})
  end

  context "with a successful request" do
    it "clears the document cache" do
      adapter.should_receive(:reset_document_cache).twice
      get '/'
    end
  end

  context "when the request raises an error" do
    it "clears the document cache" do
      adapter.should_receive(:reset_document_cache).once
      get '/fail' rescue nil
    end
  end
end
