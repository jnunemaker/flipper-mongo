require 'set'
require 'mongo'

module Flipper
  module Adapters
    class MongoSingleDocument
      class Document
        DefaultId = 'flipper'

        def initialize(collection, options = {})
          @collection = collection
          @options = options
          @id = @options[:id] || DefaultId
          @source = @options.fetch(:source) { {} }
          @criteria = {:_id => @id}
          @mongo_options = {:safe => true, :upsert => true}
        end

        def read(key)
          source[key.to_s]
        end

        def write(key, value)
          value = value.to_s
          @collection.update @criteria, {'$set' => {key.to_s => value}}, @mongo_options
          @source[key.to_s] = value
        end

        def delete(key)
          @collection.update @criteria, {'$unset' => {key.to_s => 1}}, @mongo_options
          @source.delete key.to_s
        end

        def set_members(key)
          members = source.fetch(key.to_s) { @source[key.to_s] = Set.new }

          if members.is_a?(Array)
            @source[key.to_s] = members.to_set
          else
            members
          end
        end

        def set_add(key, value)
          value = value.to_s
          @collection.update @criteria, {'$addToSet' => {key.to_s => value}}, @mongo_options
          set_members(key.to_s).add(value)
        end

        def set_delete(key, value)
          value = value.to_s
          @collection.update @criteria, {'$pull' => {key.to_s => value}}, @mongo_options
          set_members(key.to_s).delete(value)
        end

        def clear
          @loaded = nil
          @source.clear
        end

        def loaded?
          @loaded == true
        end

        private

        def source
          load unless loaded?
          @source
        end

        def load
          @loaded = true
          @source.clear
          @source.update @collection.find_one(@criteria) || {}
        end
      end
    end
  end
end
