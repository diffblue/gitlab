# frozen_string_literal: true

module Groups
  module EnterpriseUsers
    class DisassociateService < BaseService
      def initialize(user:)
        @user = user
        @group = @user.user_detail.enterprise_group
      end

      def execute
        return error('The user is not an enterprise user') unless @group

        if user_matches_the_enterprise_user_definition_for_the_group?
          return error('The user matches the "Enterprise User" definition for the group')
        end

        @user.user_detail.update!(enterprise_group_id: nil, enterprise_group_associated_at: nil)

        log_info(message: 'Disassociated the user from the enterprise group')

        success
      end
    end
  end
end
