# frozen_string_literal: true

module Vulnerabilities
  class Advisory < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    self.table_name = "vulnerability_advisories"

    validates :created_date, presence: true
    validates :published_date, presence: true
    validates :uuid, presence: true

    validates :title, length: { maximum: 2048 }
    validates :affected_range, length: { maximum: 32 }
    validates :not_impacted, length: { maximum: 2048 }
    validates :solution, length: { maximum: 2048 }
    validates :description, length: { maximum: 2048 }
    validates :cvss_v2, 'vulnerabilities/cvss_vector': { allowed_versions: [2] }, if: -> { cvss_v2.present? }
    validates :cvss_v3, 'vulnerabilities/cvss_vector': { allowed_versions: [3.0, 3.1] }, if: -> { cvss_v3.present? }

    def cvss_v2
      return unless super

      ::CvssSuite.new(super)
    end

    def cvss_v3
      return unless super

      ::CvssSuite.new(super)
    end
  end
end
