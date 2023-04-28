# frozen_string_literal: true

module Embedding
  # This model should only store public content and embeddings
  class TanukiBotMvc < Embedding::ApplicationRecord
    self.table_name = 'tanuki_bot_mvc'

    has_neighbors :embedding

    scope :neighbor_for, ->(embedding, limit:, minimum_distance:) do
      ::Embedding::TanukiBotMvc
        .nearest_neighbors(:embedding, embedding, distance: 'inner_product')
        .limit(limit)
        .select { |n| n.neighbor_distance >= minimum_distance }
    end
  end
end
