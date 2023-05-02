# frozen_string_literal: true

module CustomersDot
  class ProxyController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    feature_category :purchase
    urgency :low

    def graphql
      response = Gitlab::HTTP.post(subscription_portal_graphql_url,
        body: request.raw_post,
        headers: forward_headers
      )

      render json: response.body, status: response.code
    end

    private

    def forward_headers
      {}.tap do |headers|
        headers['Content-Type'] = 'application/json'
        headers['Authorization'] = "Bearer #{Gitlab::CustomersDot::Jwt.new(current_user).encoded}" if current_user
      end
    end
  end
end
