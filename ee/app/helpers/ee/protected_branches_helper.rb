# frozen_string_literal: true

module EE
  module ProtectedBranchesHelper
    def group_protected_branches_feature_available?(group)
      group.root? &&
        ::Feature.enabled?(:group_protected_branches, group) &&
        group.licensed_feature_available?(:group_protected_branches)
    end

    def can_admin_group_protected_branches?(group)
      can?(current_user, :admin_group, group)
    end
  end
end
