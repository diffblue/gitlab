# frozen_string_literal: true

module API
  module Ml
    class AiAssist < ::API::Base
      include APIGuard

      before do
        authenticate!
        not_found! unless current_user.groups.any? { |group| Feature.enabled?(:ai_assist_flag, group) }
      end

      allow_access_with_scope :api
      allow_access_with_scope :read_api, if: -> (request) { request.get? || request.head? }

      resource :ml do
        desc 'Get status if user can use AI Assist' do
          success EE::API::Entities::Ml::AiAssist
        end
        get 'aiassist' do
          response = {
            user_is_allowed: true
          }
          present response, with: EE::API::Entities::Ml::AiAssist
        end
      end
    end
  end
end
