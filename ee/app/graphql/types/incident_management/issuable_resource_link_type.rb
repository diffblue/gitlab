# frozen_string_literal: true

module Types
  module IncidentManagement
    class IssuableResourceLinkType < BaseObject
      graphql_name 'IssuableResourceLink'
      description 'Describes an issuable resource link for incident issues'

      authorize :admin_issuable_resource_link

      field :id,
            Types::GlobalIDType[::IncidentManagement::IssuableResourceLink],
            null: false,
            description: 'ID of the Issuable resource link.'

      field :issue,
            Types::IssueType,
            null: false,
            description: 'Incident of the resource link.'

      field :link,
            GraphQL::Types::String,
            null: false,
            description: 'Web Link to the resource.'

      field :link_text,
            GraphQL::Types::String,
            null: true,
            description: 'Optional text for the link.'

      field :link_type,
            Types::IncidentManagement::IssuableResourceLinkTypeEnum,
            null: false,
            description: 'Type of the resource link.'
    end
  end
end
