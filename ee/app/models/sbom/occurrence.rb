# frozen_string_literal: true

module Sbom
  class Occurrence < ApplicationRecord
    belongs_to :component, optional: false
    belongs_to :component_version
    belongs_to :project, optional: false
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :source

    validates :commit_sha, presence: true

    validate :component_version_belongs_to_component

    def component_version_belongs_to_component
      return unless component_version_id

      if component_version.component_id != component_id
        errors.add(:component_version, 'must belong to the associated component')
      end
    end
  end
end
