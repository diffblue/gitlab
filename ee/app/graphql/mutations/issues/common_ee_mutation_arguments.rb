# frozen_string_literal: true

module Mutations
  module Issues
    module CommonEEMutationArguments
      extend ActiveSupport::Concern

      included do
        argument :health_status,
                 ::Types::HealthStatusEnum,
                 required: false,
                 description: 'The desired health status.'

        argument :weight, GraphQL::Types::Int,
                 required: false,
                 description: 'The weight of the issue.'
      end
    end
  end
end
