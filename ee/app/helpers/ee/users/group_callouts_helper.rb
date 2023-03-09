# frozen_string_literal: true

module EE
  module Users
    module GroupCalloutsHelper
      UNLIMITED_MEMBERS_DURING_TRIAL_ALERT = 'unlimited_members_during_trial_alert'

      def show_unlimited_members_during_trial_alert?(group)
        !user_dismissed_for_group(UNLIMITED_MEMBERS_DURING_TRIAL_ALERT, group) &&
          ::Namespaces::FreeUserCap::Enforcement.new(group).qualified_namespace? &&
          group.trial_active? &&
          can_admin_group_member?(group)
      end
    end
  end
end
