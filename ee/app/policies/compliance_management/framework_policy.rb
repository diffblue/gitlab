# frozen_string_literal: true

module ComplianceManagement
  class FrameworkPolicy < BasePolicy
    delegate { @subject.namespace }

    condition(:custom_compliance_frameworks_enabled) do
      @subject.namespace.feature_available?(:custom_compliance_frameworks)
    end

    condition(:group_level_compliance_pipeline_enabled) do
      @subject.namespace.feature_available?(:evaluate_group_level_compliance_pipeline)
    end

    rule { can?(:owner_access) & custom_compliance_frameworks_enabled }.policy do
      enable :manage_compliance_framework
    end

    rule { can?(:owner_access) & group_level_compliance_pipeline_enabled }.policy do
      enable :manage_group_level_compliance_pipeline_config
    end
  end
end
