require 'set'
require 'forwardable'
require 'mongo'
require 'flipper/adapters/mongo/document'

module Flipper
  module Adapters
    class Mongo
      extend Forwardable

      def initialize(collection, options = {})
        @collection = collection
        @options = options
      end

      def_delegators :document, :read, :write, :delete, :set_members, :set_add, :set_delete

      private

      def document
        Document.new(@collection, :id => @options[:id])
      end
    end
  end
end
