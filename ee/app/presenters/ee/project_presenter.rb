# frozen_string_literal: true

module EE
  module ProjectPresenter
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Utils::DelegatorOverride

    delegator_override :approver_groups
    def approver_groups
      ::ApproverGroup.filtered_approver_groups(project.approver_groups, current_user)
    end
  end
end
