require 'set'
require 'mongo'
require 'flipper/adapters/mongo'

module Flipper
  module Adapters
    class MongoWithTTL < Mongo

      def initialize(collection, id, options = {})
        super collection, id
        @options = options
      end

      private

      # Override Mongo adapters load
      def load
        if expired?
          @document = fresh_load
        end
      end

      def fresh_load
        @last_load_at = Time.now.to_i
        @collection.find_one(@mongo_criteria) || {}
      end

      def ttl
        @options.fetch(:ttl) { 0 }
      end

      def expired?
        return true if never_loaded?
        Time.now.to_i >= (@last_load_at + ttl)
      end

      def never_loaded?
        @last_load_at.nil?
      end
    end
  end
end
