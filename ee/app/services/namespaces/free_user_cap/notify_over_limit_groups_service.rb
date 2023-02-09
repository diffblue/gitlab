# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class NotifyOverLimitGroupsService
      ServiceError = Class.new(StandardError)

      attr_accessor :group

      def self.execute(group:)
        new(group: group).execute
      end

      def initialize(group:)
        @group = group.root_ancestor
      end

      def execute
        return unless enforce_over_limit_mails?
        return unless over_limit?

        notify

        ServiceResponse.success
      rescue StandardError => e
        ServiceResponse.error message: e.message
      end

      private

      def over_limit?
        Namespaces::FreeUserCap::Enforcement.new(@group).over_limit?
      end

      def notify
        email_owners
        mark_group_as_notified!
      end

      def checked_at
        @checked_at ||= Time.current
      end

      def enforce_over_limit_mails?
        ::Namespaces::FreeUserCap.over_user_limit_mails_enabled? && ::Gitlab::CurrentSettings.dashboard_limit_enabled?
      end

      def email_owners
        @group.owners.each { |owner| ::Notify.over_free_user_limit_email(owner, @group, checked_at).deliver_now }
      end

      def mark_group_as_notified!
        @group.namespace_details.update free_user_cap_over_limit_notified_at: checked_at
      end
    end
  end
end
