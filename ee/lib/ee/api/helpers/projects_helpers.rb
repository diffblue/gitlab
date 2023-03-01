# frozen_string_literal: true

module EE
  module API
    module Helpers
      module ProjectsHelpers
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          params :optional_create_project_params_ee do
            optional :use_custom_template, type: Grape::API::Boolean, desc: "Use custom template"
            given :use_custom_template do
              optional :group_with_project_templates_id, type: Integer, desc: "Group ID that serves as the template source"
            end
          end

          params :optional_project_params_ee do
            optional :only_allow_merge_if_all_status_checks_passed, type: Grape::API::Boolean, desc: 'Blocks merge requests from merging unless all status checks have passed'
            optional :approvals_before_merge, type: Integer, desc: 'How many approvers should approve merge request by default', allow_blank: false
            optional :mirror, type: Grape::API::Boolean, desc: 'Enables pull mirroring in a project'
            optional :mirror_trigger_builds, type: Grape::API::Boolean, desc: 'Pull mirroring triggers builds'
            optional :external_authorization_classification_label, type: String, desc: 'The classification label for the project'
            optional :requirements_access_level, type: String, values: %w(disabled private enabled), desc: 'Requirements feature access level. One of `disabled`, `private` or `enabled`'
          end

          params :optional_filter_params_ee do
            optional :wiki_checksum_failed, type: Grape::API::Boolean, default: false, desc: 'Limit by projects where wiki checksum is failed'
            optional :repository_checksum_failed, type: Grape::API::Boolean, default: false, desc: 'Limit by projects where repository checksum is failed'
          end

          params :optional_update_params_ee do
            optional :allow_pipeline_trigger_approve_deployment, type: Grape::API::Boolean, desc: 'Allow pipeline triggerer to approve deployments'
            optional :mirror_user_id, type: Integer, desc: 'User responsible for all the activity surrounding a pull mirror event. Can only be set by admins'
            optional :only_mirror_protected_branches, type: Grape::API::Boolean, desc: 'Only mirror protected branches'
            optional :mirror_branch_regex, type: String, desc: 'Only mirror branches match regex'
            mutually_exclusive :only_mirror_protected_branches, :mirror_branch_regex
            optional :mirror_overwrites_diverged_branches, type: Grape::API::Boolean, desc: 'Pull mirror overwrites diverged branches'
            optional :import_url, type: String, desc: 'URL from which the project is imported'
            optional :fallback_approvals_required, type: Integer, desc: 'Overall approvals required when no rule is present'
            optional :issues_template, type: String, desc: 'Default description for Issues. Description is parsed with GitLab Flavored Markdown.'
            optional :merge_requests_template, type: String, desc: 'Default description for merge requests. Description is parsed with GitLab Flavored Markdown.'
            optional :merge_pipelines_enabled, type: Grape::API::Boolean, desc: 'Enable merged results pipelines.'
            optional :merge_trains_enabled, type: Grape::API::Boolean, desc: 'Enable merge trains.'
          end
        end

        class_methods do
          # We don't use "override" here as this module is included into various
          # API classes, and for reasons unknown the override would be verified
          # in the context of the including class, and not in the context of
          # `API::Helpers::ProjectsHelpers`.
          #
          # Likely this is related to
          # https://gitlab.com/gitlab-org/gitlab-foss/issues/50911.
          def update_params_at_least_one_of
            super.concat [
              :allow_pipeline_trigger_approve_deployment,
              :only_allow_merge_if_all_status_checks_passed,
              :approvals_before_merge,
              :external_authorization_classification_label,
              :fallback_approvals_required,
              :import_url,
              :issues_template,
              :merge_requests_template,
              :merge_pipelines_enabled,
              :merge_trains_enabled,
              :requirements_access_level
            ]
          end
        end

        override :filter_attributes_using_license!
        def filter_attributes_using_license!(attrs)
          super

          unless ::License.feature_available?(:external_authorization_service_api_management)
            attrs.delete(:external_authorization_classification_label)
          end

          unless ::License.feature_available?(:protected_environments)
            attrs.delete(:allow_pipeline_trigger_approve_deployment)
          end
        end

        override :filter_attributes_under_feature_flag!
        def filter_attributes_under_feature_flag!(attrs, project)
          super

          attrs.delete(:mirror_branch_regex) unless ::Feature.enabled?(:mirror_only_branches_match_regex, project)
        end
      end
    end
  end
end
