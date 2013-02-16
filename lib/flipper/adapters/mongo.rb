require 'set'
require 'forwardable'
require 'mongo'

module Flipper
  module Adapters
    class Mongo
      include Flipper::Adapter

      # Private: The key that stores the set of known features.
      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      def initialize(collection)
        @collection = collection
        @name = :mongo
      end

      # Public
      def get(feature)
        result = {}
        doc = find(feature.key)

        feature.gates.each do |gate|
          result[gate.key] = case gate.data_type
          when :boolean, :integer
            doc[gate.key.to_s]
          when :set
            doc.fetch(gate.key.to_s) { Set.new }.to_set
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
          update feature.key, '$set' => {
            gate.key.to_s => thing.value.to_s,
          }
        when :set
          update feature.key, '$addToSet' => {
            gate.key.to_s => thing.value.to_s,
          }
        else
          unsupported_data_type(gate.data_type)
        end

        true
      end

      # Public
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          remove feature.key
        when :integer
          update feature.key, '$set' => {gate.key.to_s => thing.value.to_s}
        when :set
          update feature.key, '$pull' => {gate.key.to_s => thing.value.to_s}
        else
          unsupported_data_type(gate.data_type)
        end

        true
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        update FeaturesKey, '$addToSet' => {'features' => feature.name.to_s}
        true
      end

      # Public: The set of known features.
      def features
        find(FeaturesKey).fetch('features') { Set.new }.to_set
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      # Private
      def find(key)
        @collection.find_one(criteria(key)) || {}
      end

      # Private
      def update(key, updates)
        options = {:upsert => true}
        @collection.update criteria(key), updates, options
      end

      # Private
      def remove(key)
        @collection.remove criteria(key)
      end

      # Private
      def criteria(key)
        {:_id => key.to_s}
      end
    end
  end
end
