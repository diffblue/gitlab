# frozen_string_literal: true
module Sbom
  class VulnerableComponentVersion < ApplicationRecord
    belongs_to :advisory,
               class_name: "Vulnerabilities::Advisory",
               foreign_key: "vulnerability_advisory_id",
               optional: false
    belongs_to :component_version,
               class_name: "Sbom::ComponentVersion",
               foreign_key: "sbom_component_version_id",
               optional: false
  end
end
