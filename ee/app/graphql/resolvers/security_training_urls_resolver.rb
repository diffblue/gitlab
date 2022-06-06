# frozen_string_literal: true

module Resolvers
  class SecurityTrainingUrlsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type [::Types::Security::TrainingUrlType], null: true

    authorize :access_security_and_compliance
    authorizes_object!

    argument :identifier_external_ids,
         [GraphQL::Types::String],
         required: true,
         description: 'List of external IDs of vulnerability identifiers.'

    argument :language,
         GraphQL::Types::String,
         required: false,
         description: 'Desired language for training urls.'

    argument :filename,
         GraphQL::Types::String,
         required: false,
         description: 'Filename to filter security training URLs by programming language.'

    alias_method :project, :object

    def resolve(**args)
      ::Security::TrainingUrlsFinder.new(
        project,
        args[:identifier_external_ids],
        args[:language],
        args[:filename]
      ).execute
    end
  end
end
