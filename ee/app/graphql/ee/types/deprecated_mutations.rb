# frozen_string_literal: true

module EE
  module Types
    module DeprecatedMutations
      extend ActiveSupport::Concern

      prepended do
        mount_aliased_mutation 'CreateIteration', ::Mutations::Iterations::Create,
          deprecated: { reason: 'Use iterationCreate', milestone: '14.0' }
      end
    end
  end
end
