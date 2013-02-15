require 'set'
require 'forwardable'
require 'mongo'
require 'flipper/adapters/mongo/document'

module Flipper
  module Adapters
    class MongoSingleDocument
      extend Forwardable

      FeaturesKey = :flipper_features

      attr_reader :name

      def initialize(collection, options = {})
        @collection = collection
        @options = options
        @name = :mongo_single_document
        @document_cache = false
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
