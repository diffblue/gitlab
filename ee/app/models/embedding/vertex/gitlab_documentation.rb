# frozen_string_literal: true

module Embedding
  module Vertex
    class GitlabDocumentation < ::Embedding::ApplicationRecord
      self.table_name = 'vertex_gitlab_docs'

      include BulkInsertSafe
      include EachBatch

      has_neighbors :embedding

      scope :current, -> { where(version: current_version) }
      scope :previous, -> { where("version < ?", current_version) }
      scope :for_version, ->(version) { where(version: version) }
      scope :for_source, ->(source) { where("metadata->>'source' = ?", source) }
      scope :for_sources, ->(sources) { where("metadata->>'source' IN (?)", sources) }
      scope :nil_embeddings_for_version, ->(version) { where(version: version, embedding: nil) }

      scope :neighbor_for, ->(embedding, limit:) do
        nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(limit)
      end

      def self.current_version_cache_key
        'vertex_gitlab_documentation:version:current'
      end

      def self.current_version
        1
      end
    end
  end
end
