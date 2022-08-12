# frozen_string_literal: true

module EE
  module Types
    module DeprecatedMutations
      extend ActiveSupport::Concern

      prepended do
        mount_aliased_mutation 'CreateIteration', ::Mutations::Iterations::Create,
          deprecated: { reason: 'Use iterationCreate', milestone: '14.0' }
        mount_mutation ::Mutations::AppSec::Fuzzing::API::CiConfiguration::Create,
          deprecated: { reason: 'The configuration snippet is now generated client-side', milestone: '15.1' }
      end
    end
  end
end
