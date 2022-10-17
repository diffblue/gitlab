# frozen_string_literal: true

module API
  module Ml
    class AiAssist < ::API::Base
      include APIGuard

      before do
        authenticate!

        allowed_groups = 0
        current_user.groups.each { |group| allowed_groups += 1 if Feature.enabled?(:ai_assist_flag, group) == true }
        not_found! unless allowed_groups > 0
      end

      allow_access_with_scope :api
      allow_access_with_scope :read_api, if: -> (request) { request.get? || request.head? }

      resource :ml do
        desc 'Get status if user can use AI Assist' do
          success EE::API::Entities::Ml::AiAssist
        end
        get 'aiassist' do
          response = {
            user_is_allowed: ::License.feature_available?(:ai_assist)
          }
          present response, with: EE::API::Entities::Ml::AiAssist
        end
      end
    end
  end
end
