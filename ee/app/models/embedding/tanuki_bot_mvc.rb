# frozen_string_literal: true

module Embedding
  # This model should only store public content and embeddings
  class TanukiBotMvc < Embedding::ApplicationRecord
    self.table_name = 'tanuki_bot_mvc'

    has_neighbors :embedding

    scope :current, -> { where(version: get_current_version) }
    scope :previous, -> { where("version < ?", get_current_version) }
    scope :nil_embeddings_for_version, ->(version) { where(version: version, embedding: nil) }

    scope :neighbor_for, ->(embedding, limit:) do
      ::Embedding::TanukiBotMvc.nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(limit)
    end

    def self.current_version_cache_key
      'tanuki_bot_mvc:version:current'
    end

    def self.get_current_version
      Gitlab::Redis::SharedState.with do |redis|
        redis.get(current_version_cache_key)
      end.to_i
    end

    def self.set_current_version!(version)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(current_version_cache_key, version.to_i)
      end.to_i
    end
  end
end
