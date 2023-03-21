# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class ClearOverLimitGroupNotificationService
      def self.execute(group:)
        new(group: group).execute
      end

      def initialize(group:)
        @group = group.root_ancestor
      end

      def execute
        clear unless over_limit?

        ServiceResponse.success
      rescue StandardError => error
        ServiceResponse.error message: error.message
      end

      private

      attr_accessor :group

      def clear
        group.namespace_details.update! free_user_cap_over_limit_notified_at: nil
      end

      def over_limit?
        ::Namespaces::FreeUserCap::Enforcement.new(group).over_limit?
      end
    end
  end
end
