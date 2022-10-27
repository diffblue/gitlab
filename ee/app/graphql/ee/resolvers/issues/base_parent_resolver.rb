# frozen_string_literal: true

module EE
  module Resolvers
    module Issues
      module BaseParentResolver
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :health_status, ::Types::HealthStatusEnum,
                   required: false,
                   deprecated: { reason: 'Use `healthStatusFilter`', milestone: '15.4' },
                   description: 'Health status of the issue.'
        end
      end
    end
  end
end
