# frozen_string_literal: true

module Resolvers
  class SecurityTrainingUrlsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type [::Types::Security::TrainingUrlType], null: true

    authorize :read_security_resource
    authorizes_object!

    argument :identifier_external_ids,
         [GraphQL::Types::String],
         required: true,
         description: 'List of external IDs of vulnerability identifiers.'

    argument :filename,
         GraphQL::Types::String,
         required: false,
         description: 'Filename to filter security training URLs by programming language.'

    alias_method :project, :object

    def resolve(**args)
      ::Security::TrainingUrlsFinder.new(
        project,
        args[:identifier_external_ids],
        args[:filename]
      ).execute
    end
  end
end
