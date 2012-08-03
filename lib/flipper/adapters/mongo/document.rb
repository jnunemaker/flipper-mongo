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
          @id = @options.fetch(:id) { DefaultId }
          @source = @options.fetch(:source) { {} }
          @criteria = {:_id => @id}
          @mongo_options = {:safe => true, :upsert => true}
        end

        def read(key)
          source[key]
        end

        def write(key, value)
          @collection.update @criteria, {'$set' => {key => value}}, @mongo_options
          @source[key] = value
        end

        def delete(key)
          @collection.update @criteria, {'$unset' => {key => 1}}, @mongo_options
          @source.delete key
        end

        def set_members(key)
          members = source.fetch(key) { @source[key] = Set.new }

          if members.is_a?(Array)
            @source[key] = members.to_set
          else
            members
          end
        end

        def set_add(key, value)
          @collection.update @criteria, {'$addToSet' => {key => value}}, @mongo_options
          set_members(key).add(value)
        end

        def set_delete(key, value)
          @collection.update @criteria, {'$pull' => {key => value}}, @mongo_options
          set_members(key).delete(value)
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
