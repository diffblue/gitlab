# frozen_string_literal: true
module Vulnerabilities
  class Advisory < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    VECTOR_MAX_LENGTH = 128

    self.table_name = "vulnerability_advisories"

    validates :created_date, presence: true
    validates :published_date, presence: true
    validates :uuid, presence: true

    validates :title, length: { maximum: 2048 }
    validates :affected_range, length: { maximum: 32 }
    validates :not_impacted, length: { maximum: 2048 }
    validates :solution, length: { maximum: 2048 }
    validates :cvss_v2, length: { maximum: VECTOR_MAX_LENGTH }
    validates :description, length: { maximum: 2048 }

    validate :validate_cvss_v3, if: -> { cvss_v3.present? }

    def cvss_v3
      return unless super

      ::Gitlab::Vulnerabilities::Cvss::V3.new(super)
    end
    strong_memoize_attr :cvss_v3

    def validate_cvss_v3
      if cvss_v3.vector.length > VECTOR_MAX_LENGTH
        # Validated here as this is a DB constraint and not part of the CVSS v3 specification.
        errors.add(:cvss_v3, "vector string may not be longer than #{VECTOR_MAX_LENGTH} characters")

        return
      end

      return if cvss_v3.valid?

      cvss_v3.errors.each { |error| errors.add(:cvss_v3, error) }
    end
  end
end
