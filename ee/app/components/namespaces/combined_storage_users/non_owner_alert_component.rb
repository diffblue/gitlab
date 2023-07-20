# frozen_string_literal: true

module Namespaces
  module CombinedStorageUsers
    class NonOwnerAlertComponent < BaseAlertComponent
      private

      def render?
        return false unless non_owner_access?

        super
      end

      def non_owner_access?
        return false if Ability.allowed?(user, :owner_access, root_namespace)

        Ability.allowed?(user, :read_group, root_namespace)
      end

      def show_cta
        false
      end

      def alert_body
        safe_format(_("Your Free top-level group, %{group_name}, has more than %{free_users_limit} users " \
                      "and uses more than %{free_storage_limit} of data. " \
                      "After usage limits are applied to Free top-level groups, " \
                      "projects in this group will be in a %{read_only_link_start}read-only state%{link_end}. " \
                      "To ensure that your group does not become read-only, " \
                      "you should contact a user with the Owner role for this group " \
                      "to upgrade to a paid tier, or manage your usage. " \
                      "For more information about the upcoming usage limits, " \
                      "see our %{faq_link_start}FAQ%{link_end}."), alert_body_params)
      end
    end
  end
end
