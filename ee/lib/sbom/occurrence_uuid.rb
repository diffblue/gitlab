# frozen_string_literal: true

module Sbom
  class OccurrenceUUID
    def self.generate(project_id:, component_id:, component_version_id:, source_id:)
      Gitlab::UUID.v5("#{project_id}-#{component_id}-#{component_version_id}-#{source_id}")
    end
  end
end
