# frozen_string_literal: true

module Vulnerabilities
  class FindingSignature < ApplicationRecord
    include BulkInsertSafe
    include VulnerabilityFindingSignatureHelpers

    self.table_name = 'vulnerability_finding_signatures'

    belongs_to :finding, foreign_key: 'finding_id', inverse_of: :signatures, class_name: 'Vulnerabilities::Finding'
    enum algorithm_type: VulnerabilityFindingSignatureHelpers::ALGORITHM_TYPES, _prefix: :algorithm
    validates :finding, presence: true

    scope :by_project, -> (project) { joins(:finding).where(vulnerability_occurrences: { project_id: project.id }) }
    scope :by_signature_sha, -> (shas) { where(signature_sha: shas) }
    scope :eager_load_comparison_entities, -> { includes(finding: [:scanner, :primary_identifier]) }

    def signature_hex
      signature_sha.unpack1("H*")
    end

    def eql?(other)
      other.is_a?(self.class) &&
        other.algorithm_type == algorithm_type &&
          other.signature_sha == signature_sha
    end

    alias_method :==, :eql?
  end
end
