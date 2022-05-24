# frozen_string_literal: true

module EE
  module Emails
    module Members
      def provisioned_member_access_granted_email(member_id)
        @member_id = member_id

        return unless member_exists?

        @user = member.user

        email_with_layout(
          to: member.user.email,
          subject: subject("Welcome to GitLab"))
      end
    end
  end
end
