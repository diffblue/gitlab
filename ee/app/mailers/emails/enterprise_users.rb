# frozen_string_literal: true

module Emails
  module EnterpriseUsers
    def enterprise_user_account_created_email(user_id)
      @user = User.find_by_id(user_id)
      return unless @user
      return unless @user.user_detail.enterprise_group

      email_with_layout(
        to: @user.email,
        subject: subject(_('Enterprise User Account on GitLab')))
    end
  end
end
