# frozen_string_literal: true

module Types
  module Sbom
    # Authorization checks are implemented on the parent object.
    class LicenseType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
      field :name, GraphQL::Types::String,
        null: false, description: 'Name of the license.'

      field :url, GraphQL::Types::String,
        null: false, description: 'License URL in relation to SPDX.'
    end
  end
end
