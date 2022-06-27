# frozen_string_literal: true

module Sbom
  class Component < ApplicationRecord
    enum component_type: {
      library: 0
    }

    validates :component_type, presence: true
    validates :name, presence: true, length: { maximum: 255 }
  end
end
