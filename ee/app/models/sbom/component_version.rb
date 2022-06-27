# frozen_string_literal: true

module Sbom
  class ComponentVersion < ApplicationRecord
    belongs_to :component, optional: false

    validates :version, presence: true, length: { maximum: 255 }
  end
end
