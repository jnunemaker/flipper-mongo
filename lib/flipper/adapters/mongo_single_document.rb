require 'set'
require 'forwardable'
require 'mongo'
require 'flipper/adapters/mongo/document'

module Flipper
  module Adapters
    class MongoSingleDocument
      extend Forwardable

      def initialize(collection, options = {})
        @collection = collection
        @options = options
        @document_cache = false
      end

      def_delegators :document, :read, :write, :delete, :set_members, :set_add, :set_delete

      def using_document_cache?
        @document_cache == true
      end

      def document_cache=(value)
        reset_document_cache
        @document_cache = value
      end

      def use_document_cache(&block)
        original = @document_cache
        @document_cache = true
        yield
      ensure
        @document_cache = original
      end

      def reset_document_cache
        @document = nil
      end

      private

      def document
        if @document_cache == true
          @document ||= fresh_document
        else
          fresh_document
        end
      end

      def fresh_document
        Document.new(@collection, :id => @options[:id])
      end
    end
  end
end
