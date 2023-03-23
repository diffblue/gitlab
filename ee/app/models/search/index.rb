# frozen_string_literal: true

module Search
  class Index < ApplicationRecord
    MAX_BUCKET_NUMBER = Search::INDEX_PARTITIONING_HASHING_MODULO - 1

    has_many :namespace_index_assignments, foreign_key: :search_index_id, inverse_of: :index
    has_many :namespaces, through: :namespace_index_assignments

    validates_presence_of :path, :type
    validates :bucket_number, numericality: {
      allow_nil: true,
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: MAX_BUCKET_NUMBER
    }
    validates :type, uniqueness: {
      scope: :path, message: 'violates unique constraint between [:type, :path]'
    }
    validates :type, uniqueness: {
      scope: :bucket_number, message: 'violates unique constraint between [:type, :bucket_number]'
    }

    class << self
      def route(hash:)
        if hash > MAX_BUCKET_NUMBER
          raise ArgumentError, "hash must be less than or equal to max bucket number: #{MAX_BUCKET_NUMBER}"
        end

        next_index(bucket_number: hash) || create_default_index_with_max_bucket_number!
      end

      def next_index(bucket_number:)
        where(bucket_number: bucket_number...).order(:bucket_number).first
      end

      def indexed_class
        raise NotImplementedError, "#{name} does not have `self.indexed_class` defined"
      end

      def create_default_index_with_max_bucket_number!
        create!(path: legacy_index_path, bucket_number: MAX_BUCKET_NUMBER)
      rescue ActiveRecord::RecordNotUnique
        find_by!(path: legacy_index_path, bucket_number: MAX_BUCKET_NUMBER)
      end

      private

      def legacy_index_path
        helper = ::Gitlab::Elastic::Helper.default
        helper.target_index_name(target: indexed_class.__elasticsearch__.index_name)
      end
    end
  end
end
