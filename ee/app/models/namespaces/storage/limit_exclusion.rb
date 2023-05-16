# frozen_string_literal: true

module Namespaces
  module Storage
    class LimitExclusion < ApplicationRecord
      self.table_name = "namespaces_storage_limit_exclusions"

      belongs_to :namespace, optional: false

      validates :namespace, uniqueness: true
      validates :reason, presence: true, length: { maximum: 255 }
    end
  end
end
