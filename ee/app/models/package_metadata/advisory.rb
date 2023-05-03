# frozen_string_literal: true

module PackageMetadata
  class Advisory < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    MAX_URL_SIZE = 512

    has_many :affected_packages, inverse_of: :advisory, foreign_key: :pm_advisory_id

    enum source_xid: ::Enums::PackageMetadata.advisory_sources

    validates :advisory_xid, presence: true, length: { maximum: 36 }
    validates :source_xid, presence: true
    validates :published_date, presence: true
    validates :title, length: { maximum: 256 }
    validates :description, length: { maximum: 8192 }
    validates :cvss_v2, 'vulnerabilities/cvss_vector': { allowed_versions: [2] }, if: -> { cvss_v2.present? }
    validates :cvss_v3, 'vulnerabilities/cvss_vector': { allowed_versions: [3.0, 3.1] }, if: -> { cvss_v3.present? }
    validates :identifiers, json_schema: { filename: 'pm_advisory_identifiers' }
    validates_each :urls do |record, _, urls|
      urls.each do |url|
        record.errors.add(url, "size is greater than #{MAX_URL_SIZE}") if url.size > MAX_URL_SIZE
      end
    end

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
