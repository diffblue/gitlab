# frozen_string_literal: true

module Types
  class DastSiteValidationType < BaseObject
    graphql_name 'DastSiteValidation'
    description 'Represents a DAST Site Validation'

    authorize :read_on_demand_scans

    field :id, ::Types::GlobalIDType[::DastSiteValidation], null: false,
          description: 'Global ID of the site validation.'

    field :status, Types::DastSiteProfileValidationStatusEnum, null: false,
          description: 'Status of the site validation.',
          method: :state

    field :normalized_target_url, GraphQL::Types::String, null: true,
          description: 'Normalized URL of the target to be validated.'

    def normalized_target_url
      object.url_base
    end
  end
end
