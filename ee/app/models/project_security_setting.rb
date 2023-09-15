# frozen_string_literal: true
#
class ProjectSecuritySetting < ApplicationRecord
  self.primary_key = :project_id

  # Note: Even if we store settings for all types of security scanning
  # Currently, Auto-fix feature is available only for container_scanning and
  # dependency_scanning features.
  AVAILABLE_AUTO_FIX_TYPES = [:dependency_scanning, :container_scanning].freeze

  belongs_to :project, inverse_of: :security_setting

  def auto_fix_enabled?
    return false if Feature.disabled?(:security_auto_fix, project)
    return false unless project.feature_available?(:vulnerability_auto_fix)

    auto_fix_enabled_types.any?
  end

  def auto_fix_enabled_types
    AVAILABLE_AUTO_FIX_TYPES.filter_map do |type|
      type if public_send("auto_fix_#{type}") # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def set_continuous_vulnerability_scans!(enabled:)
    enabled if update!(continuous_vulnerability_scans_enabled: enabled)
  end
end
