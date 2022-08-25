# frozen_string_literal: true

module EE
  module Types
    module EnvironmentType
      extend ActiveSupport::Concern

      prepended do
        field :protected_environments,
              ::Types::ProtectedEnvironmentType.connection_type,
              description: 'Protected Environments for the environment.',
              resolver: ::Resolvers::Environments::ProtectedEnvironmentsResolver
      end
    end
  end
end
