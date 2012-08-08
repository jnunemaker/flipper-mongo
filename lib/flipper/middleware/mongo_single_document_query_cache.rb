module Flipper
  module Middleware
    class MongoSingleDocumentQueryCache
      class Body
        def initialize(target, adapter, original)
          @target   = target
          @adapter  = adapter
          @original = original
        end

        def each(&block)
          @target.each(&block)
        end

        def close
          @target.close if @target.respond_to?(:close)
        ensure
          @adapter.document_cache = @original
        end
      end

      def initialize(app, adapter)
        @app = app
        @adapter = adapter
      end

      def call(env)
        original = @adapter.using_document_cache?
        @adapter.document_cache = true

        status, headers, body = @app.call(env)
        [status, headers, Body.new(body, @adapter, original)]
      end
    end
  end
end
