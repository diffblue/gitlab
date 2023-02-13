# frozen_string_literal: true

# This class represents a software license.
# For use in the License Management feature.
class SoftwareLicense < ApplicationRecord
  include Presentable

  validates :name, presence: true, uniqueness: true
  validates :spdx_identifier, length: { maximum: 255 }

  scope :by_name, -> (names) { where(name: names) }
  scope :by_spdx, -> (spdx_identifier) { where(spdx_identifier: spdx_identifier) }
  scope :ordered, -> { order(:name) }
  scope :spdx, -> { where.not(spdx_identifier: nil) }
  scope :unknown, -> { where(spdx_identifier: nil) }
  scope :grouped_by_name, -> { group(:name) }
  scope :unreachable_limit, -> { limit(500) }

  def self.unclassified_licenses_for(project)
    spdx.id_not_in(project.software_licenses).ordered.unreachable_limit
  end

  def self.all_license_names
    spdx.ordered.unreachable_limit.pluck_names
  end

  def self.pluck_names
    pluck(:name)
  end

  def self.create_policy_for!(project:, name:, classification:, scan_result_policy_read: nil)
    project.software_license_policies.create!(
      classification: classification,
      software_license: safe_find_or_create_by!(name: name),
      scan_result_policy_read: scan_result_policy_read
    )
  end

  def canonical_id
    spdx_identifier || name.downcase
  end
end
