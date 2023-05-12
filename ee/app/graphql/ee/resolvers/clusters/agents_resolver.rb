# frozen_string_literal: true

module EE
  module Resolvers
    module Clusters
      module AgentsResolver
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :has_vulnerabilities, GraphQL::Types::Boolean,
            required: false,
            description: 'Returns only cluster agents which have vulnerabilities.'
          argument :has_remote_development_agent_config, GraphQL::Types::Boolean,
            required: false,
            description: 'Returns only cluster agents which have an associated remote development agent config.'
        end
      end
    end
  end
end
