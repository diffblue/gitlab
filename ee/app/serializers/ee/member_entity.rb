# frozen_string_literal: true

module EE
  module MemberEntity
    extend ActiveSupport::Concern

    prepended do
      expose :using_license do |member|
        can?(current_user, :owner_access, group) && member.user&.using_gitlab_com_seat?(group)
      end

      expose :group_sso?, as: :group_sso

      expose :group_managed_account?, as: :group_managed_account

      expose :can_override do |member|
        member.can_override?
      end

      expose :override, as: :is_overridden

      expose :provisioned_by_this_group?, as: :provisioned_by_this_group

      expose :can_unban do |member|
        member.can_unban?
      end

      expose :banned do |member|
        member.user.present? && member.user.banned_from_namespace?(group)
      end
    end

    private

    def group
      options[:group]
    end
  end
end
