require 'set'
require 'mongo'

module Flipper
  module Adapters
    class Mongo
      DefaultId = 'flipper'

      def initialize(collection, options = {})
        @collection = collection
        @options = options
        @mongo_criteria = {:_id => id}
        @mongo_options = {:upsert => true, :safe => true}
      end

      def read(key)
        read_key(key)
      end

      def write(key, value)
        update '$set' => {key => value}
      end

      def delete(key)
        update '$unset' => {key => 1}
      end

      def set_add(key, value)
        update '$addToSet' => {key => value}
      end

      def set_delete(key, value)
        update '$pull' => {key => value}
      end

      def set_members(key)
        read_key(key) { Set.new }.to_set
      end

      private

      def id
        @id ||= @options.fetch(:id) { DefaultId }
      end

      def update(updates)
        @collection.update(@mongo_criteria, updates, @mongo_options)
      end

      def read_key(key, &block)
        load

        if block_given?
          @document.fetch(key, &block)
        else
          @document[key]
        end
      end

      def load
        @document = @collection.find_one(@mongo_criteria) || {}
      end
    end
  end
end
