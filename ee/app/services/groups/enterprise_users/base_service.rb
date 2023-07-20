# frozen_string_literal: true

module Groups
  module EnterpriseUsers
    class BaseService
      def execute
        raise NotImplementedError
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

      def user_provisioned_by_group?
        @user.user_detail.provisioned_by_group_id == @group.id
      end

      def user_group_member_and_group_subscription_was_purchased_or_renewed_2021_02_01_or_later?
        @group.member?(@user) &&
          (@group.paid? && @group.gitlab_subscription.start_date >= Date.new(2021, 2, 1))
      end

      # The "Enterprise User" definition: https://about.gitlab.com/handbook/support/workflows/gitlab-com_overview.html#enterprise-users
      def user_matches_the_enterprise_user_definition_for_the_group?
        @group.owner_of_email?(@user.email) && (
          user_was_created_2021_02_01_or_later? ||
          user_has_saml_or_scim_identity_tied_to_group? ||
          user_provisioned_by_group? ||
          user_group_member_and_group_subscription_was_purchased_or_renewed_2021_02_01_or_later?)
      end
    end
  end
end
