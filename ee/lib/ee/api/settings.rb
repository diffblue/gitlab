# frozen_string_literal: true

module EE
  module API
    module Settings
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          # rubocop:disable Metrics/CyclomaticComplexity
          # rubocop:disable Metrics/PerceivedComplexity
          override :filter_attributes_using_license
          def filter_attributes_using_license(attrs)
            unless ::License.feature_available?(:repository_mirrors)
              attrs = attrs.except(*::EE::ApplicationSettingsHelper.repository_mirror_attributes)
            end

            unless ::License.feature_available?(:email_additional_text)
              attrs = attrs.except(:email_additional_text)
            end

            unless ::License.feature_available?(:custom_file_templates)
              attrs = attrs.except(:file_template_project_id)
            end

            unless ::License.feature_available?(:default_project_deletion_protection)
              attrs = attrs.except(:default_project_deletion_protection)
            end

            unless License.feature_available?(:adjourned_deletion_for_projects_and_groups)
              attrs = attrs.except(:delayed_project_deletion, :delayed_group_deletion, :deletion_adjourned_period)
            end

            unless License.feature_available?(:disable_name_update_for_users)
              attrs = attrs.except(:updating_name_disabled_for_users)
            end

            unless License.feature_available?(:admin_merge_request_approvers_rules)
              attrs = attrs.except(*EE::ApplicationSettingsHelper.merge_request_appovers_rules_attributes)
            end

            unless License.feature_available?(:package_forwarding)
              attrs = attrs.except(
                :npm_package_requests_forwarding,
                :pypi_package_requests_forwarding,
                :maven_package_requests_forwarding
              )
            end

            unless ::Gitlab::RegistrationFeatures::PasswordComplexity.feature_available?
              attrs = attrs.except(*EE::ApplicationSettingsHelper.password_complexity_attributes)
            end

            unless License.feature_available?(:default_branch_protection_restriction_in_groups)
              attrs = attrs.except(:group_owners_can_manage_default_branch_protection)
            end

            unless License.feature_available?(:git_two_factor_enforcement) && ::Feature.enabled?(:two_factor_for_cli)
              attrs = attrs.except(:git_two_factor_session_expiry)
            end

            unless RegistrationFeatures::MaintenanceMode.feature_available?
              attrs = attrs.except(:maintenance_mode, :maintenance_mode_message)
            end

            unless License.feature_available?(:git_abuse_rate_limit)
              attrs = attrs.except(*EE::ApplicationSettingsHelper.git_abuse_rate_limit_attributes)
            end

            unless License.feature_available?(:disable_personal_access_tokens)
              attrs = attrs.except(:disable_personal_access_tokens)
            end

            attrs
          end
          # rubocop:enable Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/PerceivedComplexity
        end
      end
    end
  end
end
