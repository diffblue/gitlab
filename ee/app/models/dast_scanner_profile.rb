# frozen_string_literal: true

class DastScannerProfile < ApplicationRecord
  include Sanitizable

  belongs_to :project

  validates :project_id, presence: true
  validates :name, length: { maximum: 255 }, uniqueness: { scope: :project_id }, presence: true

  scope :project_id_in, -> (project_ids) { where(project_id: project_ids) }
  scope :with_name, -> (name) { where(name: name) }
  scope :with_project, -> { includes(:project) }

  enum scan_type: {
    passive: 1,
    active: 2
  }

  sanitizes! :name

  def self.names(scanner_profile_ids)
    find(*scanner_profile_ids).pluck(:name)
  rescue ActiveRecord::RecordNotFound
    []
  end

  def ci_variables(dast_site_profile: nil)
    ::Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'DAST_SPIDER_MINS', value: String(spider_timeout)) if spider_timeout
      variables.append(key: 'DAST_TARGET_AVAILABILITY_TIMEOUT', value: String(target_timeout)) if target_timeout
      variables.append(key: 'DAST_USE_AJAX_SPIDER', value: String(use_ajax_spider))
      variables.append(key: 'DAST_DEBUG', value: String(show_debug_messages))
      variables.append(key: 'DAST_FULL_SCAN_ENABLED', value: String(active?))

      next unless dast_site_profile&.api?

      if active?
        variables.append(key: 'DAST_API_PROFILE', value: 'Quick-Active')
      else
        variables.append(key: 'DAST_API_PROFILE', value: 'Quick')
      end
    end
  end

  def referenced_in_security_policies
    return [] unless project.all_security_orchestration_policy_configurations.present?

    project
      .all_security_orchestration_policy_configurations
      .map { |configuration| configuration.active_policy_names_with_dast_scanner_profile(name) }
      .inject(&:merge)
      .to_a
  end
end
