# frozen_string_literal: true

module EE
  module Types
    module SubscriptionType
      extend ActiveSupport::Concern

      prepended do
        field :ai_completion_response,
          subscription: ::Subscriptions::AiCompletionResponse, null: true,
          description: 'Triggered when a response from AI integration is received.',
          alpha: { milestone: '15.11' }

        field :issuable_weight_updated,
          subscription: Subscriptions::IssuableUpdated, null: true,
          description: 'Triggered when the weight of an issuable is updated.'

        field :issuable_iteration_updated,
          subscription: Subscriptions::IssuableUpdated, null: true,
          description: 'Triggered when the iteration of an issuable is updated.'

        field :issuable_health_status_updated,
          subscription: Subscriptions::IssuableUpdated, null: true,
          description: 'Triggered when the health status of an issuable is updated.'

        field :issuable_epic_updated,
          subscription: Subscriptions::IssuableUpdated, null: true,
          description: 'Triggered when the epic of an issuable is updated.'
      end
    end
  end
end
