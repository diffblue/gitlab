# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class ClearOverLimitNotificationService
      ServiceError = Class.new(StandardError)

      def self.execute(root_namespace:)
        new(root_namespace: root_namespace).execute
      end

      def initialize(root_namespace:)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def execute
        clear unless over_limit?

        ServiceResponse.success
      rescue ServiceError => error
        ServiceResponse.error message: error.message
      end

      private

      attr_reader :root_namespace

      def clear
        root_namespace.namespace_details.update! free_user_cap_over_limit_notified_at: nil
      end

      def over_limit?
        ::Namespaces::FreeUserCap::Enforcement.new(root_namespace).over_limit?
      end
    end
  end
end
