# frozen_string_literal: true

module GroupSaml
  module Identity
    class DestroyService
      attr_reader :identity

      delegate :user, to: :identity

      def initialize(identity)
        @identity = identity
      end

      def execute(transactional: false)
        with_transaction(transactional) do
          identity.destroy!
          remove_group_access
        end
      end

      private

      def with_transaction(transactional, &block)
        transactional ? ::Identity.transaction { yield } : yield
      end

      def remove_group_access
        return unless group_membership
        return if group.last_owner?(user)

        Members::DestroyService.new(user).execute(group_membership)
      end

      def group
        @group ||= identity.saml_provider.group
      end

      def group_membership
        @group_membership ||= group.member(user)
      end
    end
  end
end
