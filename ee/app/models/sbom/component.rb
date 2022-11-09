# frozen_string_literal: true

module Sbom
  class Component < ApplicationRecord
    enum component_type: ::Enums::Sbom.component_types
    enum purl_type: ::Enums::Sbom.purl_types

    validates :component_type, presence: true
    validates :name, presence: true, length: { maximum: 255 }
  end
end
