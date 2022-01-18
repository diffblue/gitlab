# frozen_string_literal: true

module Resolvers
  class SecurityTrainingProvidersResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::Security::TrainingType, null: false

    authorize :access_security_and_compliance
    authorizes_object!

    argument :only_enabled, GraphQL::Types::Boolean,
             required: false,
             description: "Filter the list by only enabled security trainings."

    def resolve(only_enabled: false)
      ::Security::TrainingProvider.for_project(object, only_enabled: only_enabled)
    end
  end
end
