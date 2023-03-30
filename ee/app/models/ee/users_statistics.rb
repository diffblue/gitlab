# frozen_string_literal: true

module EE
  module UsersStatistics
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    def billable
      (base_billable_users + guest_billable_users).sum
    end

    def non_billable
      bots + non_billable_guests
    end

    def non_billable_guests
      with_highest_role_guest - with_highest_role_guest_with_custom_role
    end

    override :active
    def active
      super + with_highest_role_minimal_access
    end

    private

    def base_billable_users
      [
        with_highest_role_reporter,
        with_highest_role_developer,
        with_highest_role_maintainer,
        with_highest_role_owner
      ]
    end

    def guest_billable_users
      if License.current&.exclude_guests_from_active_count?
        [with_highest_role_guest_with_custom_role]
      else
        [without_groups_and_projects, with_highest_role_guest, with_highest_role_minimal_access]
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      private

      override :highest_role_stats
      def highest_role_stats
        super.merge(
          with_highest_role_minimal_access: batch_count_for_access_level(::Gitlab::Access::MINIMAL_ACCESS),
          with_highest_role_guest_with_custom_role: count_guests_with_elevating_custom_role)
      end

      def count_guests_with_elevating_custom_role
        ::Gitlab::Database::BatchCount.batch_count(::User.guests_with_elevating_role)
      end
    end
  end
end
