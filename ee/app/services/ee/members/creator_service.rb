# frozen_string_literal: true

module EE
  module Members
    module CreatorService
      extend ::Gitlab::Utils::Override

      private

      override :member_attributes
      def member_attributes
        super.merge(ldap: ldap)
      end

      def after_commit_tasks
        super

        expire_free_plan_counter_cache
      end

      def expire_free_plan_counter_cache
        # Using `source.members_and_requesters` in Members::CreatorService#find_or_initialize_member_by_user
        # affects memoization on billed_user_ids_including_guests in
        # this creation callback for a similar reason as the one mentioned in the
        # Members::CreatorService#find_or_initialize_member_by_user method.
        # Before with `source.members.build` the memoization didn't need explicitly cleared,
        # since the `source.root_ancestor` was re-found with that relation.
        # This is since `source.members` was really a scope and caused a fresh
        # finding on the source(sort of like finding the source.root_ancestor again manually). Since we are now
        # going through the traditional `members_and_requests` relation that isn't using a scope, it
        # doesn't refresh the `source.root_ancestor` finding from the last member add, so we need
        # to clear the memoization here due to cached counts when batch members are added in the same request cycle.

        return unless member.persisted?

        source.root_ancestor.expire_free_plan_members_count_cache
      end
    end
  end
end
