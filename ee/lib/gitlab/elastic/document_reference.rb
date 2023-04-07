# frozen_string_literal: true

module Gitlab
  module Elastic
    # Tracks some essential information needed to tie database and elasticsearch
    # records together, and to delete ES documents when the database object no
    # longer exists.
    #
    # A custom serialisation format suitable for Redis is included.
    class DocumentReference
      include Gitlab::Utils::StrongMemoize

      DEFAULT_DELIMITER = '|'
      LEGACY_DELIMITER = ' '

      PRELOAD_BATCH_SIZE = 1_000

      InvalidError = Class.new(StandardError)

      class Collection
        include Enumerable

        def initialize
          @refs = []
        end

        def deserialize_and_add(string)
          @refs << ::Gitlab::Elastic::DocumentReference.deserialize(string)
        end

        def each(&blk)
          @refs.each(&blk)
        end

        def preload_database_records
          @refs.group_by(&:klass).each do |klass, group|
            group.each_slice(PRELOAD_BATCH_SIZE) do |group_slice|
              ids = group_slice.map(&:db_id)

              records = klass.id_in(ids).preload_indexing_data
              records_by_id = records.index_by(&:id)

              group_slice.each do |ref|
                ref.database_record = records_by_id[ref.db_id.to_i]
              end
            end
          end

          self
        end
      end

      class << self
        def build(instance)
          new(instance.class, instance.id, instance.es_id, instance.es_parent)
        end

        def serialize(anything)
          case anything
          when String
            anything
          when Gitlab::Elastic::DocumentReference
            anything.serialize
          when ApplicationRecord
            serialize_record(anything)
          when Array
            serialize_array(anything)
          else
            raise InvalidError, "Don't know how to serialize #{anything.class}"
          end
        end

        def serialize_record(record)
          serialize_array([record.class.to_s, record.id, record.es_id, record.es_parent].compact)
        end

        def serialize_array(array)
          test_array!(array)

          array.join(LEGACY_DELIMITER)
        end

        def deserialize(string)
          delimiter = string.include?(DEFAULT_DELIMITER) ? DEFAULT_DELIMITER : LEGACY_DELIMITER
          deserialize_array(string.split(delimiter))
        end

        def deserialize_array(array)
          test_array!(array)

          new(*array)
        end

        private

        def test_array!(array)
          raise InvalidError, "Bad array representation: #{array.inspect}" unless
            (3..4).cover?(array.size)
        end
      end

      attr_reader :klass, :db_id, :es_id

      # This attribute is nil for some records, e.g., projects
      attr_reader :es_parent

      def initialize(klass_or_name, db_id, es_id, es_parent = nil)
        @klass = klass_or_name
        @klass = klass_or_name.constantize if @klass.is_a?(String)
        @db_id = db_id
        @es_id = es_id
        @es_parent = es_parent
      end

      def ==(other)
        other.instance_of?(self.class) &&
          self.serialize == other.serialize
      end

      def klass_name
        klass.to_s
      end

      def database_record
        strong_memoize(:database_record) { klass.find_by_id(db_id) }
      end

      def database_record=(record)
        strong_memoize(:database_record) { record }
      end

      def serialize
        self.class.serialize_array([klass_name, db_id, es_id, es_parent].compact)
      end
    end
  end
end
