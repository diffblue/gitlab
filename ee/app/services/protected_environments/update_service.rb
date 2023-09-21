# frozen_string_literal: true
module ProtectedEnvironments
  class UpdateService < ProtectedEnvironments::BaseService
    include ::Audit::Changes

    AUDITABLE_ATTRIBUTES = [:required_approval_count].freeze

    def execute(protected_environment)
      # before updating the `protected_environment`, we need to query upfront
      # the `deploy_access_levels` and `approval_rules` records that are marked for destruction
      # since `protected_environment.deploy_access_levels` and `protected_environment.approval_rules`
      # will no longer include these records after update
      deploy_access_levels_for_destruction = find_deploy_access_levels_for_destruction(protected_environment)
      approval_rules_for_destruction = find_approval_rules_for_destruction(protected_environment)

      protected_environment.update(sanitized_params).tap do |is_updated|
        if is_updated
          log_audit_events(
            protected_environment: protected_environment,
            deleted_deploy_access_levels: deploy_access_levels_for_destruction,
            deleted_approval_rules: approval_rules_for_destruction
          )
        end
      end
    end

    private

    def find_deploy_access_levels_for_destruction(protected_environment)
      return [] unless sanitized_params[:deploy_access_levels_attributes].present?

      ids = sanitized_params[:deploy_access_levels_attributes].filter_map { |dal| dal[:id] if dal[:_destroy] }
      protected_environment.deploy_access_levels.id_in(ids).to_a
    end

    def find_approval_rules_for_destruction(protected_environment)
      return [] unless sanitized_params[:approval_rules_attributes].present?

      ids = sanitized_params[:approval_rules_attributes].filter_map { |ar| ar[:id] if ar[:_destroy] }
      protected_environment.approval_rules.id_in(ids).to_a
    end

    def log_audit_events(protected_environment:, deleted_deploy_access_levels:, deleted_approval_rules:)
      audit_changed_attributes(protected_environment)

      audit_authorization_rule_changes(
        protected_environment: protected_environment,
        deleted_deploy_access_levels: deleted_deploy_access_levels,
        deleted_approval_rules: deleted_approval_rules
      )
    end

    def audit_changed_attributes(protected_environment)
      AUDITABLE_ATTRIBUTES.each do |attr_name|
        audit_changes(
          attr_name,
          entity: container,
          model: protected_environment,
          event_type: 'protected_environment_updated'
        )
      end
    end

    def audit_authorization_rule_changes(
      protected_environment:,
      deleted_deploy_access_levels:,
      deleted_approval_rules:
    )
      ::Audit::ProtectedEnvironmentAuthorizationRuleChangesAuditor.new(
        author: current_user,
        scope: container,
        protected_environment: protected_environment,
        deleted_deploy_access_levels: deleted_deploy_access_levels,
        deleted_approval_rules: deleted_approval_rules
      ).audit
    end
  end
end
