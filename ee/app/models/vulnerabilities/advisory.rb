# frozen_string_literal: true
module Vulnerabilities
  class Advisory < ApplicationRecord
    self.table_name = "vulnerability_advisories"

    validates :created_date, presence: true
    validates :published_date, presence: true
    validates :uuid, presence: true

    validates :title, length: { maximum: 2048 }
    validates :affected_range, length: { maximum: 32 }
    validates :not_impacted, length: { maximum: 2048 }
    validates :solution, length: { maximum: 2048 }
    validates :cvss_v2, length: { maximum: 128 }
    validates :cvss_v3, length: { maximum: 128 }
    validates :description, length: { maximum: 2048 }
  end
end
