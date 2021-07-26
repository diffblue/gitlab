# frozen_string_literal: true

module Types
  module Dast
    class SiteProfileAuthType < BaseObject
      graphql_name 'DastSiteProfileAuth'
      description 'Input type for DastSiteProfile authentication'

      present_using ::Dast::SiteProfilePresenter

      authorize :read_on_demand_scans

      field :enabled, GraphQL::Types::Boolean,
            null: true,
            method: :auth_enabled,
            description: 'Indicates whether authentication is enabled.'

      field :url, GraphQL::Types::String,
            null: true,
            method: :auth_url,
            description: 'The URL of the page containing the sign-in HTML ' \
                         'form on the target website.'

      field :username_field, GraphQL::Types::String,
            null: true,
            method: :auth_username_field,
            description: 'The name of username field at the sign-in HTML form.'

      field :password_field, GraphQL::Types::String,
            null: true,
            method: :auth_password_field,
            description: 'The name of password field at the sign-in HTML form.'

      field :username, GraphQL::Types::String,
            null: true,
            method: :auth_username,
            description: 'The username to authenticate with on the target website.'

      field :password, GraphQL::Types::String,
            null: true,
            description: 'Redacted password to authenticate with on the target website.'
    end
  end
end
