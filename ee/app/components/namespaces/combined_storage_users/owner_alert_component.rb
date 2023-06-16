# frozen_string_literal: true

module Namespaces
  module CombinedStorageUsers
    class OwnerAlertComponent < BaseAlertComponent
      private

      def render?
        return false unless Ability.allowed?(user, :owner_access, root_namespace)

        super
      end

      def show_cta
        true
      end

      def alert_body
        safe_format(_("Your top-level group, %{group_name}, has more than %{free_users_limit} users " \
                      "and uses more than %{free_storage_limit} of data. " \
                      "After usage limits are applied to Free top-level groups, " \
                      "projects in this group will be in a %{read_only_link_start}read-only state%{link_end}. " \
                      "To get more seats and additional storage, upgrade to a paid tier. " \
                      "You can also manage your usage. " \
                      "For more information about the upcoming usage limits, " \
                      "see our %{faq_link_start}FAQ%{link_end}"), alert_body_params)
      end

      def namespace_primary_cta
        link_to _('Manage usage'),
          group_usage_quotas_path(root_namespace, source: 'users-storage-limit-alert-enforcement'),
          class: 'btn gl-alert-action btn-info btn-md gl-button',
          data: {
            track_action: 'click_button',
            track_label: 'manage_users_storage_limits'
          }
      end

      def namespace_secondary_cta
        link_to _('Explore paid plans'),
          group_billings_path(root_namespace, source: 'users-storage-limit-alert-enforcement'),
          class: 'btn gl-alert-action btn-default btn-md gl-button',
          data: { track_action: 'click_button',
                  track_label: 'explore_paid_plans' }
      end
    end
  end
end
