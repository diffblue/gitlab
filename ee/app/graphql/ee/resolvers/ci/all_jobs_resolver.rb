# frozen_string_literal: true

module EE
  module Resolvers
    module Ci
      module AllJobsResolver
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :failure_reason, ::Types::Ci::JobFailureReasonEnum,
            required: false,
            alpha: { milestone: '16.4' },
            description: 'Filter jobs by failure reason. Currently only `RUNNER_SYSTEM_FAILURE` together with ' \
                         '`runnerTypes: INSTANCE_TYPE` is supported.'
        end

        override :resolve_with_lookahead
        def resolve_with_lookahead(**args)
          super
        rescue ArgumentError => e
          raise ::Gitlab::Graphql::Errors::ArgumentError, e.message
        end

        private

        override :params_data
        def params_data(args)
          super.merge(failure_reason: args[:failure_reason])
        end
      end
    end
  end
end
