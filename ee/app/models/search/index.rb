# frozen_string_literal: true

module Search
  class Index < ApplicationRecord
    MAX_BUCKET_NUMBER = Search::INDEX_PARTITIONING_HASHING_MODULO - 1

    has_many :namespace_index_assignments, foreign_key: :search_index_id, inverse_of: :index
    has_many :namespaces, through: :namespace_index_assignments

    before_validation :set_path

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

    after_create :create_advanced_search_index!, unless: :skip_create_advanced_search_index
    attr_accessor :skip_create_advanced_search_index

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
        create!(
          path: legacy_index_path,
          bucket_number: MAX_BUCKET_NUMBER,
          number_of_shards: legacy_index_settings.fetch(:number_of_shards),
          number_of_replicas: legacy_index_settings.fetch(:number_of_replicas),
          skip_create_advanced_search_index: true
        )
      rescue ActiveRecord::RecordNotUnique
        find_by!(path: legacy_index_path, bucket_number: MAX_BUCKET_NUMBER)
      end

      def global_search_alias
        indexed_class.__elasticsearch__.index_name
      end

      private

      def legacy_index_path
        new.helper.target_index_name(target: global_search_alias)
      end

      def legacy_index_settings
        @legacy_index_settings ||= new.settings(with_overrides: false).fetch(:index)
      end
    end

    def settings(with_overrides: true)
      @settings ||= parse(config.settings).tap do |hsh|
        if with_overrides
          # This overrides application settings
          hsh[:index][:number_of_shards] = number_of_shards
          hsh[:index][:number_of_replicas] = number_of_replicas
        end
      end
    end

    def mappings
      @mappings ||= parse(config.mappings)
    end

    def config
      self.class.indexed_class.__elasticsearch__
    end

    def helper
      @helper ||= ::Gitlab::Elastic::Helper.default
    end

    private

    def parse(obj)
      obj.to_hash.with_indifferent_access.deep_transform_values { |v| v.respond_to?(:call) ? v.call : v }
    end

    def create_advanced_search_index!
      helper.create_index(
        index_name: path,
        mappings: mappings,
        settings: settings,
        with_alias: false,
        alias_name: :noop,
        options: {
          skip_if_exists: true,
          meta: {
            index_id: id,
            index_type: type
          }
        }
      )
    end

    def set_path
      self.path ||= path_name_components.join('-')
    end

    def path_name_components
      [
        self.class.global_search_alias,
        (bucket_number || 'na'),
        Time.current.utc.strftime('%Y%m%d%H%M')
      ]
    end
  end
end
