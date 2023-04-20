# frozen_string_literal: true

module Embedding
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    connects_to database: { writing: :embedding, reading: :embedding } if Gitlab::Database.has_config?(:embedding)

    def self.model_name
      @model_name ||= ActiveModel::Name.new(self, nil, name.demodulize)
    end
  end

  class SchemaMigration < ApplicationRecord
    class << self
      def all_versions
        order(:version).pluck(:version)
      end
    end
  end
end
