# frozen_string_literal: true

class DastScannerProfile < ApplicationRecord
  belongs_to :project

  validates :project_id, presence: true
  validates :name, length: { maximum: 255 }, uniqueness: { scope: :project_id }, presence: true

  scope :project_id_in, -> (project_ids) { where(project_id: project_ids) }
  scope :with_name, -> (name) { where(name: name) }

  enum scan_type: {
    passive: 1,
    active: 2
  }

  def self.names(scanner_profile_ids)
    find(*scanner_profile_ids).pluck(:name)
  rescue ActiveRecord::RecordNotFound
    []
  end

  def ci_variables
    ::Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'DAST_SPIDER_MINS', value: String(spider_timeout)) if spider_timeout
      variables.append(key: 'DAST_TARGET_AVAILABILITY_TIMEOUT', value: String(target_timeout)) if target_timeout
      variables.append(key: 'DAST_FULL_SCAN_ENABLED', value: String(full_scan_enabled?))
      variables.append(key: 'DAST_USE_AJAX_SPIDER', value: String(use_ajax_spider))
      variables.append(key: 'DAST_DEBUG', value: String(show_debug_messages))
    end
  end

  def full_scan_enabled?
    scan_type == 'active'
  end

  def referenced_in_security_policies
    return [] unless project.security_orchestration_policy_configuration.present?

    project.security_orchestration_policy_configuration.active_policy_names_with_dast_scanner_profile(name)
  end
end
