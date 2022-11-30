# frozen_string_literal: true

module API
  module Entities
    class UserWithProvisionedAttrs < UserBasic
      expose :email, if: ->(user, options) do
        can_admin_group_member?(options[:current_user], user) || user.managed_by?(options[:current_user])
      end

      private

      def can_admin_group_member?(current_user, user)
        return false unless user.provisioned_by_group

        Ability.allowed?(current_user, :admin_group_member, user.provisioned_by_group)
      end
    end
  end
end
