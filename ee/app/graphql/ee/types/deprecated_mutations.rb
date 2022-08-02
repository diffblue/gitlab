# frozen_string_literal: true

module EE
  module Types
    module DeprecatedMutations
      extend ActiveSupport::Concern

      ITERATION_DEPRECATION_MESSAGE = 'Manual iteration management is deprecated. Only automatic iteration cadences ' \
                                      'will be supported in the future'

      prepended do
        mount_mutation ::Mutations::Iterations::Create,
          deprecated: { reason: ITERATION_DEPRECATION_MESSAGE, milestone: '14.10' }
        mount_mutation ::Mutations::Iterations::Delete,
          deprecated: { reason: ITERATION_DEPRECATION_MESSAGE, milestone: '14.10' }
        mount_aliased_mutation 'CreateIteration', ::Mutations::Iterations::Create,
          deprecated: { reason: ITERATION_DEPRECATION_MESSAGE, milestone: '14.0' }
        mount_mutation ::Mutations::AppSec::Fuzzing::API::CiConfiguration::Create,
          deprecated: { reason: 'The configuration snippet is now generated client-side', milestone: '15.1' }
      end
    end
  end
end
