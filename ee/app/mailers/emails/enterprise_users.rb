# frozen_string_literal: true

module Emails
  module EnterpriseUsers
    def user_associated_with_enterprise_group_email(user_id)
      @user = User.find_by_id(user_id)
      return unless @user
      return unless @user.user_detail.enterprise_group

      email_with_layout(
        to: @user.email,
        subject: subject(_('Enterprise User Account on GitLab')))
    end
  end
end
