# frozen_string_literal: true

module EE
  module UsersStatistics
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    def billable
      (base_billable_users + guest_billable_users).sum
    end

    def non_billable
      bots + with_highest_role_guest
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
        []
      else
        [without_groups_and_projects, with_highest_role_guest, with_highest_role_minimal_access]
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      private

      override :highest_role_stats
      def highest_role_stats
        super.merge(with_highest_role_minimal_access: batch_count_for_access_level(::Gitlab::Access::MINIMAL_ACCESS))
      end
    end
  end
end
