# frozen_string_literal: true

module EE
  module API
    module Entities
      class ApprovalState < Grape::Entity
        expose :merge_request, merge: true, using: ::API::Entities::IssuableEntity

        expose :merge_status, documentation: { example: 'can_be_merged' } do |approval_state|
          approval_state.merge_request.public_merge_status
        end

        expose :approved?, as: :approved, documentation: { type: 'boolean' }

        expose :approvals_required, documentation: { type: 'integer', example: 2 }

        expose :approvals_left, documentation: { type: 'integer', example: 2 }

        expose :require_password_to_approve, documentation: { type: 'boolean' } do |approval_state|
          approval_state.project.require_password_to_approve?
        end

        expose :approved_by, using: ::API::Entities::Approvals, documentation: { is_array: true } do |approval_state|
          approval_state.merge_request.approvals
        end

        expose :suggested_approvers,
          using: ::API::Entities::UserBasic, documentation: { is_array: true } do |approval_state, options|
            approval_state.suggested_approvers(current_user: options[:current_user])
          end

        # @deprecated, reads from first regular rule instead
        expose :approvers do |approval_state|
          if rule = approval_state.first_regular_rule
            rule.users.map do |user|
              { user: ::API::Entities::UserBasic.represent(user) }
            end
          else
            []
          end
        end
        # @deprecated, reads from first regular rule instead
        expose :approver_groups do |approval_state|
          if rule = approval_state.first_regular_rule
            presenter = ::ApprovalRulePresenter.new(rule, current_user: options[:current_user])
            presenter.groups.map do |group|
              { group: ::API::Entities::Group.represent(group) }
            end
          else
            []
          end
        end

        expose :user_has_approved, documentation: { type: 'boolean' } do |approval_state, options|
          approval_state.merge_request.approved_by?(options[:current_user])
        end

        expose :user_can_approve, documentation: { type: 'boolean' } do |approval_state, options|
          approval_state.eligible_for_approval_by?(options[:current_user])
        end

        expose :approval_rules_left, using: ApprovalRuleShort, documentation: { is_array: true }

        expose :has_approval_rules, documentation: { type: 'boolean' } do |approval_state|
          approval_state.user_defined_rules.present?
        end

        expose :merge_request_approvers_available, documentation: { type: 'boolean' } do |approval_state|
          approval_state.project.feature_available?(:merge_request_approvers)
        end

        expose :multiple_approval_rules_available, documentation: { type: 'boolean' } do |approval_state|
          approval_state.project.multiple_approval_rules_available?
        end

        expose :invalid_approvers_rules, using: ApprovalRuleShort, documentation: { is_array: true }
      end
    end
  end
end
