# frozen_string_literal: true

module EE
  module GraphqlTriggers
    extend ActiveSupport::Concern

    prepended do
      def self.ai_completion_response(user_gid, resource_gid, response)
        ::GitlabSchema.subscriptions.trigger(
          'aiCompletionResponse', { user_id: user_gid, resource_id: resource_gid }, response
        )
      end

      def self.issuable_weight_updated(issuable)
        ::GitlabSchema.subscriptions.trigger('issuableWeightUpdated', { issuable_id: issuable.to_gid }, issuable)
      end

      def self.issuable_iteration_updated(issuable)
        ::GitlabSchema.subscriptions.trigger('issuableIterationUpdated', { issuable_id: issuable.to_gid }, issuable)
      end

      def self.issuable_health_status_updated(issuable)
        ::GitlabSchema.subscriptions.trigger('issuableHealthStatusUpdated', { issuable_id: issuable.to_gid }, issuable)
      end

      def self.issuable_epic_updated(issuable)
        ::GitlabSchema.subscriptions.trigger('issuableEpicUpdated', { issuable_id: issuable.to_gid }, issuable)
      end
    end
  end
end
