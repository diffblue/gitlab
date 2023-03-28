# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class NotifyOverLimitService
      ServiceError = Class.new(StandardError)

      def self.execute(root_namespace:)
        new(root_namespace: root_namespace).execute
      end

      def initialize(root_namespace:)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def execute
        return unless enforce_over_limit_mails?
        return unless over_limit?

        notify

        ServiceResponse.success
      rescue ServiceError => e
        ServiceResponse.error message: e.message
      end

      private

      attr_reader :root_namespace

      def over_limit?
        Namespaces::FreeUserCap::Enforcement.new(root_namespace).over_limit?
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
        root_namespace.owners.each do |owner|
          ::Notify.over_free_user_limit_email(owner, root_namespace, checked_at).deliver_now
        end
      end

      def mark_group_as_notified!
        root_namespace.namespace_details.update free_user_cap_over_limit_notified_at: checked_at
      end
    end
  end
end
