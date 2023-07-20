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
        safe_format(_("Your Free top-level group, %{group_name}, has more than %{free_users_limit} users " \
                      "and uses more than %{free_storage_limit} of data. " \
                      "After usage limits are applied to Free top-level groups, " \
                      "projects in this group will be in a %{read_only_link_start}read-only state%{link_end}. " \
                      "You should reduce the number of users or upgrade to a paid tier " \
                      "%{strong_start}before%{strong_end} you manage your storage usage. Otherwise, " \
                      "your Free top-level group will become read-only immediately because the " \
                      "5-user limit applies. For more information, " \
                      "see our %{faq_link_start}FAQ%{link_end}."), alert_body_params)
      end

      def namespace_primary_cta
        link_to _('Explore paid plans'),
          group_billings_path(root_namespace, source: 'users-storage-limit-alert-enforcement'),
          class: 'btn gl-alert-action btn-info btn-md gl-button',
          data: { track_action: 'click_button',
                  track_label: 'explore_paid_plans' }
      end

      def namespace_secondary_cta
        link_to _('Manage usage'),
          group_usage_quotas_path(root_namespace, source: 'users-storage-limit-alert-enforcement'),
          class: 'btn gl-alert-action btn-default btn-md gl-button',
          data: {
            track_action: 'click_button',
            track_label: 'manage_users_storage_limits'
          }
      end
    end
  end
end
