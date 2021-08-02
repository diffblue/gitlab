# frozen_string_literal: true

module Vulnerabilities
  class FindingSignature < ApplicationRecord
    self.table_name = 'vulnerability_finding_signatures'

    include BulkInsertSafe
    include VulnerabilityFindingSignatureHelpers

    belongs_to :finding, foreign_key: 'finding_id', inverse_of: :signatures, class_name: 'Vulnerabilities::Finding'
    enum algorithm_type: VulnerabilityFindingSignatureHelpers::ALGORITHM_TYPES, _prefix: :algorithm
    validates :finding, presence: true

    def signature_hex
      signature_sha.unpack1("H*")
    end

    def eql?(other)
      other.algorithm_type == algorithm_type &&
        other.signature_sha == signature_sha
    end

    alias_method :==, :eql?
  end
end
