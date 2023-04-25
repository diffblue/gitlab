# frozen_string_literal: true

module Embedding
  # This model should only store public content and embeddings
  class TanukiBotMvc < Embedding::ApplicationRecord
    self.table_name = 'tanuki_bot_mvc'

    has_neighbors :embedding

    scope :neighbor_for, ->(embedding) { nearest_neighbors(:embedding, embedding, distance: 'inner_product') }
  end
end
