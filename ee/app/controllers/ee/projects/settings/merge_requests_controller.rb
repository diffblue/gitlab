# frozen_string_literal: true

module EE
  module Projects
    module Settings
      module MergeRequestsController
        extend ::Gitlab::Utils::Override
        extend ::ActiveSupport::Concern

        prepended do
          before_action do
            if @project&.licensed_feature_available?(:security_orchestration_policies)
              push_licensed_feature(:security_orchestration_policies)
            end
          end
        end

        private

        override :project_params_attributes
        def project_params_attributes
          super + project_params_ee
        end

        override :project_setting_attributes
        def project_setting_attributes
          attributes = %i[prevent_merge_without_jira_issue suggested_reviewers_enabled]

          attributes << :only_allow_merge_if_all_status_checks_passed if allow_external_status_checks?

          super + attributes
        end

        def project_params_ee
          attrs = %i[
            approvals_before_merge
            approver_group_ids
            approver_ids
            merge_requests_template
            reset_approvals_on_push
            ci_cd_only
            use_custom_template
            require_password_to_approve
            group_with_project_templates_id
          ]

          attrs << %i[merge_pipelines_enabled] if allow_merge_pipelines_params?
          attrs << %i[merge_trains_enabled] if allow_merge_trains_params?
          attrs << %i[only_allow_merge_if_all_status_checks_passed] if allow_external_status_checks?

          attrs += merge_request_rules_params

          attrs << :auto_rollback_enabled if project&.feature_available?(:auto_rollback)

          attrs
        end

        def mirror_params
          %i[
            mirror
            mirror_trigger_builds
          ]
        end

        def merge_request_rules_params
          attrs = []

          if can?(current_user, :modify_merge_request_committer_setting, project)
            attrs << :merge_requests_disable_committers_approval
          end

          if can?(current_user, :modify_approvers_rules, project)
            attrs << :disable_overriding_approvers_per_merge_request
          end

          attrs << :merge_requests_author_approval if can?(current_user, :modify_merge_request_author_setting, project)

          attrs
        end

        def allow_merge_pipelines_params?
          project&.feature_available?(:merge_pipelines)
        end

        def allow_merge_trains_params?
          project&.feature_available?(:merge_trains)
        end

        def allow_external_status_checks?
          project&.licensed_feature_available?(:external_status_checks)
        end
      end
    end
  end
end
