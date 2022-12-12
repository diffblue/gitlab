# frozen_string_literal: true

module EE
  module Types
    module PermissionTypes
      module Deployment
        extend ActiveSupport::Concern

        prepended do
          ability_field :approve_deployment,
                        description: "Indicates the user can perform `approve_deployment` on this resource. " \
                                     "This field can only be resolved for one environment in any single request." do
            extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
          end
        end
      end
    end
  end
end
