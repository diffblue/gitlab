# frozen_string_literal: true

module Subscriptions
  class CreateService
    include Gitlab::Utils::StrongMemoize

    attr_reader :current_user, :customer_params, :subscription_params

    CUSTOMERS_OAUTH_APP_UID_CACHE_KEY = 'customers_oauth_app_uid'

    def initialize(current_user, group:, customer_params:, subscription_params:)
      @current_user = current_user
      @group = group
      @customer_params = customer_params
      @subscription_params = subscription_params
    end

    def execute
      response = client.create_customer(create_customer_params)

      return response unless response[:success]

      oauth_token&.save

      # We can't use an email from GL.com because it may differ from the billing email.
      # Instead we use the email received from the CustomersDot as a billing email.
      customer_data = response.with_indifferent_access[:data][:customer]
      billing_email = customer_data[:email]
      token = customer_data[:authentication_token]

      response = client.create_subscription(create_subscription_params, billing_email, token)

      OnboardingProgressService.new(@group).execute(action: :subscription_created) if response[:success]

      response
    end

    private

    def create_customer_params
      {
        provider: 'gitlab',
        uid: current_user.id,
        credentials: credentials_attrs,
        customer: customer_attrs,
        info: info_attrs
      }
    end

    def credentials_attrs
      {
        token: oauth_token&.token
      }
    end

    def customer_attrs
      {
        country: country_code(customer_params[:country]),
        address_1: customer_params[:address_1],
        address_2: customer_params[:address_2],
        city: customer_params[:city],
        state: customer_params[:state],
        zip_code: customer_params[:zip_code],
        company: customer_params[:company]
      }
    end

    def info_attrs
      {
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        email: current_user.email
      }
    end

    def create_subscription_params
      {
        plan_id: subscription_params[:plan_id],
        payment_method_id: subscription_params[:payment_method_id],
        products: {
          main: {
            quantity: subscription_params[:quantity]
          }
        },
        gl_namespace_id: @group.id,
        gl_namespace_name: @group.name,
        preview: 'false',
        source: subscription_params[:source]
      }
    end

    def country_code(country)
      World.alpha3_from_alpha2(country)
    end

    def client
      Gitlab::SubscriptionPortal::Client
    end

    def customers_oauth_app_uid
      Rails.cache.fetch(CUSTOMERS_OAUTH_APP_UID_CACHE_KEY, expires_in: 1.hour) do
        response = client.customers_oauth_app_uid

        response.dig(:data, 'oauth_app_id')
      end
    end

    def oauth_token
      strong_memoize(:oauth_token) do
        next unless customers_oauth_app_uid

        application = Doorkeeper::Application.find_by_uid(customers_oauth_app_uid)
        existing_token = Doorkeeper::AccessToken.matching_token_for(application, current_user.id, application.scopes)

        next existing_token if existing_token

        Doorkeeper::AccessToken.new(
          application_id: application.id,
          resource_owner_id: current_user.id,
          token: Doorkeeper::OAuth::Helpers::UniqueToken.generate,
          scopes: application.scopes.to_s
        )
      end
    end
  end
end
