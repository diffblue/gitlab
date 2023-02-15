# frozen_string_literal: true

module Groups
  module EnterpriseUsers
    class CreateService
      def initialize(group:, user:)
        @group = group
        @user = user
        @group_member = group.member(user)
      end

      def execute
        return error(s_('EnterpriseUsers|The user is already an enterprise user')) if @user.provisioned_by_group_id
        return error(s_('EnterpriseUsers|The user is not a member of the group')) unless @group_member

        unless user_matches_the_enterprise_user_definition_for_the_group?
          return error(s_('EnterpriseUsers|The user does not match the "Enterprise User" definition for the group'))
        end

        if @user.user_detail.update(provisioned_by_group_id: @group.id, provisioned_by_group_at: Time.current)
          Notify.provisioned_member_access_granted_email(@group_member.id).deliver_later

          log_info(message: 'Marked the user as an enterprise user of the group')

          success
        else
          error(s_('EnterpriseUsers|The user detail cannot be updated'), reason: :user_detail_cannot_be_updated)
        end
      end

      private

      def error(message, reason: nil)
        ServiceResponse.error(message: message, payload: response_payload, reason: reason)
      end

      def success
        ServiceResponse.success(payload: response_payload)
      end

      def response_payload
        { group: @group, user: @user }
      end

      def log_info(message:)
        Gitlab::AppLogger.info(
          class: self.class.name,
          group_id: @group.id,
          user_id: @user.id,
          message: message
        )
      end

      def user_was_created_2021_02_01_or_later?
        @user.created_at >= Date.new(2021, 2, 1)
      end

      def user_has_saml_or_scim_identity_tied_to_group?
        @group.saml_provider&.identities&.for_user(@user)&.exists? || @group.scim_identities.for_user(@user).exists?
      end

      def group_subscription_was_purchased_or_renewed_2021_02_01_or_later?
        @group.paid? && @group.gitlab_subscription.start_date >= Date.new(2021, 2, 1)
      end

      # The "Enterprise User" definition: https://about.gitlab.com/handbook/support/workflows/gitlab-com_overview.html#enterprise-users
      def user_matches_the_enterprise_user_definition_for_the_group?
        @group.owner_of_email?(@user.email) && (
          user_was_created_2021_02_01_or_later? ||
          user_has_saml_or_scim_identity_tied_to_group? ||
          group_subscription_was_purchased_or_renewed_2021_02_01_or_later?)
      end
    end
  end
end
