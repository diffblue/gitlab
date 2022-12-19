# frozen_string_literal: true

module EE
  module Projects
    module MergeRequests
      module ApplicationController
        extend ActiveSupport::Concern

        private

        def merge_request_includes(association)
          super.includes( # rubocop:disable CodeReuse/ActiveRecord
            blocking_merge_requests: [
              :metrics, :assignees, :author, :head_pipeline, :milestone,
              { source_project: :route, target_project: :route }
            ]
          )
        end

        def merge_request_params
          clamp_approvals_before_merge(super)
        end

        def merge_request_params_attributes
          super.push(
            { blocking_merge_request_references: [] },
            :update_blocking_merge_request_refs,
            :remove_hidden_blocking_merge_requests,
            approval_rule_attributes,
            :approvals_before_merge,
            :approver_group_ids,
            :approver_ids,
            :reset_approval_rules_to_defaults,
            { suggested_reviewer_ids: [] }
          )
        end

        def approval_rule_attributes
          {
            approval_rules_attributes: [
              :id,
              :name,
              { user_ids: [] },
              { group_ids: [] },
              { usernames: [] },
              :approvals_required,
              :approval_project_rule_id,
              :remove_hidden_groups,
              :_destroy
            ]
          }
        end

        # If the number of approvals is not greater than the project default, set to
        # the project default, so that we fall back to the project default. And
        # still allow overriding rules defined at the project level but not allow
        # a number of approvals lower than what the project defined.
        def clamp_approvals_before_merge(mr_params)
          return mr_params unless mr_params[:approvals_before_merge]

          # Target the MR target project in priority, else it depends whether the project
          # is forked.
          target_project = if @merge_request # rubocop:disable Gitlab/ModuleWithInstanceVariables
                             @merge_request.target_project # rubocop:disable Gitlab/ModuleWithInstanceVariables
                           elsif project.forked? && project.id.to_s != mr_params[:target_project_id]
                             project.fork_network_projects.find(mr_params[:target_project_id])
                           else
                             project
                           end

          if mr_params[:approvals_before_merge].to_i < target_project.min_fallback_approvals
            mr_params[:approvals_before_merge] = target_project.min_fallback_approvals
          end

          mr_params
        end
      end
    end
  end
end
