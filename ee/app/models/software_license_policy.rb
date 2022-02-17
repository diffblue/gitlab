# frozen_string_literal: true

# This class represents a software license policy. Which means the fact that the user
# approves or not of the use of a certain software license in their project.
# For use in the License Management feature.
class SoftwareLicensePolicy < ApplicationRecord
  include Presentable
  # Mapping from old classification names to new names
  LEGACY_CLASSIFICATION_STATUS = {
    'approved' => 'allowed',
    'blacklisted' => 'denied'
  }.freeze

  # Only allows modification of the approval status
  FORM_EDITABLE = %i[approval_status].freeze

  belongs_to :project, inverse_of: :software_license_policies
  belongs_to :software_license, -> { readonly }
  attr_readonly :software_license

  enum classification: {
    denied: 0,
    allowed: 1
  }

  # Software license is mandatory, it contains the license informations.
  validates_associated :software_license
  validates_presence_of :software_license

  validates_presence_of :project
  validates :classification, presence: true

  # A license is unique for its project since it can't be approved and denied.
  validates :software_license, uniqueness: { scope: :project_id }

  scope :ordered, -> { SoftwareLicensePolicy.includes(:software_license).order("software_licenses.name ASC") }
  scope :for_project, -> (project) { where(project: project) }
  scope :with_license, -> { joins(:software_license) }
  scope :including_license, -> { includes(:software_license) }
  scope :unreachable_limit, -> { limit(1_000) }

  scope :with_license_by_name, -> (license_name) do
    with_license.where(SoftwareLicense.arel_table[:name].lower.in(Array(license_name).map(&:downcase)))
  end

  scope :by_spdx, -> (spdx_identifier) do
    with_license.where(software_licenses: { spdx_identifier: spdx_identifier })
  end

  delegate :name, :spdx_identifier, to: :software_license

  def approval_status
    if Feature.enabled?(:lc_remove_legacy_approval_status, project, default_enabled: :yaml)
      classification
    else
      legacy_approval_status
    end
  end

  def legacy_approval_status
    LEGACY_CLASSIFICATION_STATUS.key(classification)
  end

  def self.to_classification(approval_status)
    LEGACY_CLASSIFICATION_STATUS.fetch(approval_status, approval_status)
  end
end
