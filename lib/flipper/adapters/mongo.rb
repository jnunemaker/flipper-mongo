require 'set'
require 'forwardable'
require 'mongo'

module Flipper
  module Adapters
    class Mongo
      FeaturesKey = :flipper_features

      attr_reader :name

      def initialize(collection)
        @collection = collection
        @name = :mongo
        @update_options = {:safe => true, :upsert => true}
      end

      # Public
      def get(feature)
        result = {}

        feature.gates.each do |gate|
          result[gate] = case gate.data_type
          when :boolean, :integer
            read key(feature, gate)
          when :set
            set_members key(feature, gate)
          else
            unsupported_data_type(gate.data_type)
          end
        end

        result
      end

      # Public
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          write key(feature, gate), thing.value.to_s
        when :set
          set_add key(feature, gate), thing.value.to_s
        else
          unsupported_data_type(gate.data_type)
        end

        true
      end

      # Public
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          feature.gates.each do |gate|
            delete key(feature, gate)
          end
        when :integer
          write key(feature, gate), thing.value.to_s
        when :set
          set_delete key(feature, gate), thing.value.to_s
        else
          unsupported_data_type(gate.data_type)
        end

        true
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        set_add(FeaturesKey, feature.name.to_s)
        true
      end

      # Public: The set of known features.
      def features
        set_members(FeaturesKey)
      end

      # Private
      def key(feature, gate)
        "#{feature.key}/#{gate.key}"
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      def read(key)
        find_one key
      end

      def write(key, value)
        update key, {'$set' => {'v' => value.to_s}}
      end

      def delete(key)
        remove key
      end

      def set_members(key)
        (find_one(key) || Set.new).to_set
      end

      def set_add(key, value)
        update key, {'$addToSet' => {'v' => value.to_s}}
      end

      def set_delete(key, value)
        update key, {'$pull' => {'v' => value.to_s}}
      end

      private

      def find_one(key)
        doc = @collection.find_one(criteria(key))

        unless doc.nil?
          doc['v']
        end
      end

      def update(key, updates)
        @collection.update criteria(key), updates, @update_options
      end

      def remove(key)
        @collection.remove criteria(key)
      end

      def criteria(key)
        {:_id => key.to_s}
      end
    end
  end
end
