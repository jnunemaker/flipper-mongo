require 'set'
require 'forwardable'
require 'mongo'

module Flipper
  module Adapters
    class Mongo
      extend Forwardable

      def initialize(collection)
        @collection = collection
        @update_options = {:safe => true, :upsert => true}
      end

      def read(key)
        find_one key
      end

      def write(key, value)
        update key, {'$set' => {'v' => value}}
      end

      def delete(key)
        @collection.remove criteria(key)
      end

      def set_members(key)
        (find_one(key) || Set.new).to_set
      end

      def set_add(key, value)
        update key, {'$addToSet' => {'v' => value}}
      end

      def set_delete(key, value)
        update key, {'$pull' => {'v' => value}}
      end

      private

      def find_one(key)
        if (doc = @collection.find_one(criteria(key)))
          doc['v']
        end
      end

      def update(key, updates)
        @collection.update criteria(key), updates, @update_options
      end

      def criteria(key)
        {:_id => key}
      end
    end
  end
end
