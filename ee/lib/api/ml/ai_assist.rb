# frozen_string_literal: true

module API
  module Ml
    class AiAssist < ::API::Base
      include APIGuard
      feature_category :code_suggestions

      before do
        authenticate!

        # Initial feature flag check to disable the AI Assist API entirely
        not_found! unless Feature.enabled?(:ai_assist_api)
        not_found! unless current_user.can?(:access_code_suggestions)
      end

      allow_access_with_scope :api
      allow_access_with_scope :read_api, if: ->(request) { request.get? || request.head? }

      resource :ml do
        desc 'Get status if user can use AI Assist' do
          success EE::API::Entities::Ml::AiAssist
        end
        get 'ai-assist' do
          Gitlab::Tracking.event(
            'API::Ml::AiAssist',
            :authenticate,
            user: current_user,
            label: 'code_suggestions'
          )

          response = {
            user_is_allowed: true,
            third_party_ai_features_enabled: current_user.third_party_ai_features_enabled?
          }
          present response, with: EE::API::Entities::Ml::AiAssist
        end
      end
    end
  end
end
