# frozen_string_literal: true

# This class represents a software license.
# For use in the License Management feature.
class SoftwareLicense < ApplicationRecord
  include Presentable

  TransactionInProgressError = Class.new(StandardError)
  ALL_LICENSE_NAMES_CACHE_KEY = [name, 'all_license_names'].freeze
  TRANSACTION_MESSAGE = "Sub-transactions are not allowed as there is already an open transaction."

  validates :name, presence: true, uniqueness: true
  validates :spdx_identifier, length: { maximum: 255 }

  scope :by_name, -> (names) { where(name: names) }
  scope :by_spdx, -> (spdx_identifier) { where(spdx_identifier: spdx_identifier) }
  scope :ordered, -> { order(:name) }
  scope :spdx, -> { where.not(spdx_identifier: nil) }
  scope :unknown, -> { where(spdx_identifier: nil) }
  scope :grouped_by_name, -> { group(:name) }
  scope :unreachable_limit, -> { limit(500) }

  class << self
    def unclassified_licenses_for(project)
      spdx.id_not_in(project.software_licenses).ordered.unreachable_limit
    end

    def all_license_names
      Rails.cache.fetch(ALL_LICENSE_NAMES_CACHE_KEY, expires_in: 7.days) do
        spdx.ordered.unreachable_limit.pluck_names
      end
    end

    def pluck_names
      pluck(:name)
    end

    def create_policy_for!(project:, name:, classification:, scan_result_policy_read: nil)
      raise TransactionInProgressError, TRANSACTION_MESSAGE if transaction_open?

      project.software_license_policies.create!(
        classification: classification,
        software_license: safe_find_or_create_by!(name: name),
        scan_result_policy_read: scan_result_policy_read
      )
    end

    # This method will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/395776
    def unsafe_create_policy_for!(project:, name:, classification:, scan_result_policy_read: nil)
      project.software_license_policies.create!(
        classification: classification,
        software_license: find_or_create_by!(name: name),
        scan_result_policy_read: scan_result_policy_read
      )
    end

    def transaction_open?
      connection.transaction_open?
    end
  end

  def canonical_id
    spdx_identifier || name.downcase
  end
end
