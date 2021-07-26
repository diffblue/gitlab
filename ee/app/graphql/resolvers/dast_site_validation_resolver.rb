# frozen_string_literal: true

module Resolvers
  class DastSiteValidationResolver < BaseResolver
    alias_method :project, :object

    type Types::DastSiteValidationType.connection_type, null: true

    argument :normalized_target_urls, [GraphQL::Types::String],
             required: false,
             description: 'Normalized URL of the target to be scanned.'

    def resolve(**args)
      DastSiteValidationsFinder
        .new(project_id: project.id, url_base: args[:normalized_target_urls], most_recent: true)
        .execute
    end
  end
end
