# frozen_string_literal: true

module EE
  module Mutations
    module Ci
      module NamespaceCiCdSettingsUpdate
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :allow_stale_runner_pruning, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates if stale runners directly belonging to this namespace should ' \
              'be periodically pruned.'
        end
      end
    end
  end
end
