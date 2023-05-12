# frozen_string_literal: true

module API
  module Ml
    class AiAssist < ::API::Base
      include APIGuard
      feature_category :code_suggestions
      accessible_root_groups = nil

      before do
        authenticate!

        # Initial feature flag check to disable the AI Assist API entirely
        not_found! unless Feature.enabled?(:ai_assist_api)

        # Check if the feature is enabled for any of the user's groups
        accessible_root_groups = current_user.groups.by_parent(nil)
        not_found! unless accessible_root_groups.any?(&:code_suggestions_enabled?)
      end

      allow_access_with_scope :api
      allow_access_with_scope :read_api, if: -> (request) { request.get? || request.head? }

      resource :ml do
        desc 'Get status if user can use AI Assist' do
          success EE::API::Entities::Ml::AiAssist
        end
        get 'ai-assist' do
          response = {
            user_is_allowed: accessible_root_groups.present?
          }
          present response, with: EE::API::Entities::Ml::AiAssist
        end
      end
    end
  end
end
