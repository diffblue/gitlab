# frozen_string_literal: true

module Types
  class DastSiteValidationType < BaseObject
    graphql_name 'DastSiteValidation'
    description 'Represents a DAST Site Validation'

    authorize :read_on_demand_dast_scan

    field :id, ::Types::GlobalIDType[::DastSiteValidation],
      null: false, description: 'Global ID of the site validation.'

    field :status, Types::DastSiteProfileValidationStatusEnum,
      null: false, method: :state, description: 'Status of the site validation.'

    field :normalized_target_url, GraphQL::Types::String,
      null: true, method: :url_base, description: 'Normalized URL of the target to be validated.'

    field :validation_started_at, Types::TimeType,
          null: true, description: 'Timestamp of when the validation started.'
  end
end
