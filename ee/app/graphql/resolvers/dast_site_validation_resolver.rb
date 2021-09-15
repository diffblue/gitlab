# frozen_string_literal: true

module Resolvers
  class DastSiteValidationResolver < BaseResolver
    alias_method :project, :object

    type Types::DastSiteValidationType.connection_type, null: true

    argument :normalized_target_urls, [GraphQL::Types::String],
             required: false,
             description: 'Normalized URL of the target to be scanned.'

    argument :status, Types::DastSiteValidationStatusEnum,
             required: false,
             description: 'Status of the site validation. Ignored if `dast_failed_site_validations` feature flag is disabled.'

    def resolve(**args)
      args.delete(:status) unless Feature.enabled?(:dast_failed_site_validations, project, default_enabled: :yaml)

      DastSiteValidationsFinder
        .new(project_id: project.id, url_base: args[:normalized_target_urls], state: args[:status], most_recent: true)
        .execute
    end
  end
end
