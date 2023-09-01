# frozen_string_literal: true

module Groups
  module EnterpriseUsers
    class AssociateService < BaseService
      def initialize(group:, user:)
        @group = group
        @user = user
      end

      def execute
        if @user.enterprise_user_of_group?(@group)
          return error(s_('EnterpriseUsers|The user is already an enterprise user of the group'))
        end

        unless user_matches_the_enterprise_user_definition_for_the_group?
          return error(s_('EnterpriseUsers|The user does not match the "Enterprise User" definition for the group'))
        end

        @user.user_detail.update!(enterprise_group_id: @group.id, enterprise_group_associated_at: Time.current)

        Notify.user_associated_with_enterprise_group_email(@user.id).deliver_later

        log_info(message: 'Associated the user with the enterprise group')

        success
      end
    end
  end
end
