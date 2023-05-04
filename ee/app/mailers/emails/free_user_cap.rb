# frozen_string_literal: true

module Emails
  module FreeUserCap
    def over_free_user_limit_email(user, namespace, checked_at)
      email = user.notification_email_or_default

      @start_trial_url = new_trial_url(namespace_id: namespace.id)
      @billings_url_track_cta = group_billings_url namespace, source: 'over-user-limit-email-btn-cta'
      @billings_url_track_link = group_billings_url namespace, source: 'over-user-limit-email-upgrade-link'
      @manage_users_url = group_usage_quotas_url namespace, anchor: 'seats-quota-tab'
      @namespace_name = namespace.name
      @checked_at = Time.zone.parse checked_at.to_s

      email_with_layout(
        to: email,
        subject: s_("FreeUserCap|You've reached your member limit!"))
    end
  end
end
