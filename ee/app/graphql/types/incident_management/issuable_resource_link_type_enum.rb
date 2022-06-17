# frozen_string_literal: true

module Types
  module IncidentManagement
    class IssuableResourceLinkTypeEnum < BaseEnum
      graphql_name 'IssuableResourceLinkType'
      description 'Issuable resource link type enum'

      ::IncidentManagement::IssuableResourceLink.link_types.keys.each do |link_type|
        value link_type, value: link_type, description: "#{link_type.titleize} link type"
      end
    end
  end
end
