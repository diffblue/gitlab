# frozen_string_literal: true

module Resolvers
  class NetworkPolicyResolver < BaseResolver
    type Types::NetworkPolicyType, null: true

    argument :environment_id,
             ::Types::GlobalIDType[::Environment],
             required: false,
             description: 'Global ID of the environment to filter policies.'

    alias_method :project, :object

    def resolve(**)
      []
    end
  end
end
