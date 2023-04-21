# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    class Client
      include SubscriptionPortal::Clients::Rest
      include SubscriptionPortal::Clients::Graphql

      ResponseError = Class.new(StandardError)

      class << self
        private

        def json_headers
          {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
          }
        end

        def admin_headers
          json_headers.merge(
            {
              'X-Admin-Email' => Gitlab::SubscriptionPortal::SUBSCRIPTION_PORTAL_ADMIN_EMAIL,
              'X-Admin-Token' => Gitlab::SubscriptionPortal::SUBSCRIPTION_PORTAL_ADMIN_TOKEN
            }
          )
        end

        def customer_headers(email, token)
          json_headers.merge(
            {
              'X-Customer-Email' => email,
              'X-Customer-Token' => token
            }
          )
        end

        def parse_response(http_response)
          parsed_response = http_response.parsed_response

          case http_response.response
          when Net::HTTPSuccess
            { success: true, data: parsed_response }
          when Net::HTTPUnprocessableEntity
            log_error(http_response)
            { success: false, data: parsed_response.slice('errors', 'error_attribute_map') }
          else
            log_error(http_response)
            { success: false, data: { errors: "HTTP status code: #{http_response.code}" } }
          end
        end

        def log_error(response)
          Gitlab::ErrorTracking.log_exception(
            ResponseError.new('Unsuccessful response code'),
            {
              status: response.code,
              message: response.message,
              body: response.body
            }
          )
        end
      end
    end
  end
end
