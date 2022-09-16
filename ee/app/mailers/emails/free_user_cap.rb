# frozen_string_literal: true

module Emails
  module FreeUserCap
    def over_free_user_limit_email(user, namespace, checked_at)
      email = user.notification_email_or_default

      @start_trial_url = new_trial_url
      @upgrade_url = group_billings_url namespace
      @manage_users_url = group_usage_quotas_url namespace, anchor: 'seats-quota-tab'
      @namespace_name = namespace.name
      @checked_at = Time.zone.parse checked_at.to_s

      email_with_layout(
        to: email,
        subject: s_("FreeUserCap|You've reached your member limit!"))
    end
  end
end
