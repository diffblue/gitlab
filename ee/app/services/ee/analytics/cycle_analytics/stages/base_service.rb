# frozen_string_literal: true

module EE
  module Analytics
    module CycleAnalytics
      module Stages
        module BaseService
          extend ::Gitlab::Utils::Override

          private

          def error(stage)
            ServiceResponse.error(message: 'Invalid parameters', payload: { errors: stage.errors }, http_status: :unprocessable_entity)
          end

          def not_found
            ServiceResponse.error(message: 'Stage not found', http_status: :not_found)
          end
        end
      end
    end
  end
end
