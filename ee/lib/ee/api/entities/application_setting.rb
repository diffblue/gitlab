# frozen_string_literal: true

module EE
  module API
    module Entities
      module ApplicationSetting
        extend ActiveSupport::Concern

        prepended do
          expose(*EE::ApplicationSettingsHelper.repository_mirror_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:repository_mirrors)
          end)
          expose(*EE::ApplicationSettingsHelper.merge_request_appovers_rules_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:admin_merge_request_approvers_rules)
          end)
          expose(*EE::ApplicationSettingsHelper.password_complexity_attributes, if: ->(_instance, _options) do
            ::Gitlab::RegistrationFeatures::PasswordComplexity.feature_available?
          end)
          expose :email_additional_text, if: ->(_instance, _opts) { ::License.feature_available?(:email_additional_text) }
          expose :file_template_project_id, if: ->(_instance, _opts) { ::License.feature_available?(:custom_file_templates) }
          expose :default_project_deletion_protection, if: ->(_instance, _opts) { ::License.feature_available?(:default_project_deletion_protection) }
          expose :delayed_project_deletion, if: ->(_instance, _opts) { ::License.feature_available?(:adjourned_deletion_for_projects_and_groups) && ::Feature.disabled?(:always_perform_delayed_deletion) }
          expose :delayed_group_deletion, if: ->(_instance, _opts) { ::License.feature_available?(:adjourned_deletion_for_projects_and_groups) && ::Feature.disabled?(:always_perform_delayed_deletion) }
          expose :deletion_adjourned_period, if: ->(_instance, _opts) { ::License.feature_available?(:adjourned_deletion_for_projects_and_groups) }
          expose :disable_personal_access_tokens, if: ->(_instance, _opts) { ::License.feature_available?(:disable_personal_access_tokens) }
          expose :updating_name_disabled_for_users, if: ->(_instance, _opts) { ::License.feature_available?(:disable_name_update_for_users) }
          expose :maven_package_requests_forwarding, if: ->(_instance, _opts) { ::License.feature_available?(:package_forwarding) }
          expose :npm_package_requests_forwarding, if: ->(_instance, _opts) { ::License.feature_available?(:package_forwarding) }
          expose :pypi_package_requests_forwarding, if: ->(_instance, _opts) { ::License.feature_available?(:package_forwarding) }
          expose :group_owners_can_manage_default_branch_protection, if: ->(_instance, _opts) { ::License.feature_available?(:default_branch_protection_restriction_in_groups) }
          expose :maintenance_mode, if: ->(_instance, _opts) { RegistrationFeatures::MaintenanceMode.feature_available? }
          expose :maintenance_mode_message, if: ->(_instance, _opts) { RegistrationFeatures::MaintenanceMode.feature_available? }
          expose :git_two_factor_session_expiry, if: ->(_instance, _opts) { License.feature_available?(:git_two_factor_enforcement) && ::Feature.enabled?(:two_factor_for_cli) }
          expose(*EE::ApplicationSettingsHelper.git_abuse_rate_limit_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:git_abuse_rate_limit)
          end)
        end
      end
    end
  end
end
