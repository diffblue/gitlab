# frozen_string_literal: true

module EE
  module Gitlab
    module GonHelper
      extend ::Gitlab::Utils::Override

      override :add_gon_variables
      def add_gon_variables
        super

        gon.roadmap_epics_limit = 1000

        if current_user && defined?(Llm)
          ai_chat = {
            total_model_token: ::Llm::ExplainCodeService::TOTAL_MODEL_TOKEN_LIMIT,
            max_response_token: ::Llm::ExplainCodeService::MAX_RESPONSE_TOKENS,
            input_content_limit: ::Llm::ExplainCodeService::INPUT_CONTENT_LIMIT
          }

          push_to_gon_attributes('ai', 'chat', ai_chat)
        end

        if ::Gitlab.com?
          gon.subscriptions_url                = ::Gitlab::Routing.url_helpers.subscription_portal_url
          gon.subscriptions_legacy_sign_in_url = ::Gitlab::Routing.url_helpers.subscription_portal_legacy_sign_in_url
          gon.payment_form_url                 = ::Gitlab::Routing.url_helpers.subscription_portal_payment_form_url
          gon.payment_validation_form_id       = ::Gitlab::SubscriptionPortal::PAYMENT_VALIDATION_FORM_ID
          gon.registration_validation_form_url = ::Gitlab::Routing.url_helpers
                                                                  .subscription_portal_registration_validation_form_url
        end
      end

      # Exposes if a licensed feature is available.
      #
      # name - The name of the licensed feature
      # obj  - the object to check the licensed feature on (project, namespace)
      def push_licensed_feature(name, obj = nil)
        enabled = if obj
                    obj.feature_available?(name)
                  else
                    ::License.feature_available?(name) || ::GitlabSubscriptions::Features.usage_ping_feature?(name)
                  end

        push_to_gon_attributes(:licensed_features, name, enabled)
      end
    end
  end
end
