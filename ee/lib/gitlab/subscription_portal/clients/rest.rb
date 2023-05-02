# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    module Clients
      module Rest
        extend ActiveSupport::Concern

        class_methods do
          SubscriptionPortalRESTException = Class.new(RuntimeError)

          def generate_trial(params)
            trial_user_params = params[:trial_user] ? params : { trial_user: params }
            http_post("trials", admin_headers, trial_user_params)
          end

          def generate_lead(params)
            http_post("trials/create_hand_raise_lead", admin_headers, params)
          end

          def create_customer(params)
            http_post("api/customers", admin_headers, params)
          end

          def create_subscription(params, email, token)
            http_post("subscriptions", customer_headers(email, token), params)
          end

          def payment_form_params(payment_type)
            http_get("payment_forms/#{payment_type}", admin_headers)
          end

          def payment_method(id)
            http_get("api/payment_methods/#{id}", admin_headers)
          end

          def validate_payment_method(id, params)
            http_post("api/payment_methods/#{id}/validate", admin_headers, params)
          end

          def customers_oauth_app_uid
            http_get("api/v1/oauth_app_id", admin_headers)
          end

          private

          def error_message
            _('Our team has been notified. Please try again.')
          end

          def track_exception(message)
            Gitlab::ErrorTracking.track_exception(SubscriptionPortalRESTException.new(message))
          end

          def base_url
            ::Gitlab::Routing.url_helpers.subscription_portal_url
          end

          def http_get(path, headers)
            response = Gitlab::HTTP.get("#{base_url}/#{path}", headers: headers)

            parse_response(response)
          rescue *Gitlab::HTTP::HTTP_ERRORS => e
            track_exception(e.message)
            { success: false, data: { errors: error_message } }
          end

          def http_post(path, headers, params = {})
            response = Gitlab::HTTP.post("#{base_url}/#{path}", body: params.to_json, headers: headers)

            parse_response(response)
          rescue *Gitlab::HTTP::HTTP_ERRORS => e
            track_exception(e.message)
            { success: false, data: { errors: error_message } }
          end

          def http_put(path, headers, params = {})
            response = Gitlab::HTTP.put("#{base_url}/#{path}", body: params.to_json, headers: headers)

            parse_response(response)
          rescue *Gitlab::HTTP::HTTP_ERRORS => e
            track_exception(e.message)
            { success: false, data: { errors: error_message } }
          end
        end
      end
    end
  end
end
