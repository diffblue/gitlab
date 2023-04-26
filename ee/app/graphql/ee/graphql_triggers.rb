# frozen_string_literal: true

module EE
  module GraphqlTriggers
    extend ActiveSupport::Concern

    prepended do
      def self.ai_completion_response(user_gid, resource_gid, response)
        ::GitlabSchema.subscriptions.trigger(
          :ai_completion_response, { user_id: user_gid, resource_id: resource_gid }, response
        )
      end

      def self.issuable_weight_updated(issuable)
        ::GitlabSchema.subscriptions.trigger(:issuable_weight_updated, { issuable_id: issuable.to_gid }, issuable)
      end

      def self.issuable_iteration_updated(issuable)
        ::GitlabSchema.subscriptions.trigger(:issuable_iteration_updated, { issuable_id: issuable.to_gid }, issuable)
      end

      def self.issuable_health_status_updated(issuable)
        ::GitlabSchema.subscriptions.trigger(
          :issuable_health_status_updated, { issuable_id: issuable.to_gid }, issuable
        )
      end

      def self.issuable_epic_updated(issuable)
        ::GitlabSchema.subscriptions.trigger(:issuable_epic_updated, { issuable_id: issuable.to_gid }, issuable)
      end
    end
  end
end
