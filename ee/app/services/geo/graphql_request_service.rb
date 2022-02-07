# frozen_string_literal: true

module Geo
  class GraphqlRequestService < RequestService
    include Gitlab::Geo::LogHelpers

    attr_reader :node, :user

    def initialize(node, user)
      @node = node
      @user = user
    end

    def execute(body)
      super(graphql_url, body, with_response: true)
    end

    private

    def graphql_url
      node&.graphql_url
    end

    def headers
      return super unless user.present?

      Gitlab::Geo::JsonRequest.new(scope: ::Gitlab::Geo::API_SCOPE, authenticating_user_id: user.id).headers
    end
  end
end
