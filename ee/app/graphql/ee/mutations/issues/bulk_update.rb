# frozen_string_literal: true

module EE
  module Mutations
    module Issues
      module BulkUpdate
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :iteration_id, ::Types::GlobalIDType[::Iteration],
            required: false,
            description: 'Global ID of the iteration that will be assigned to the issues.'
        end

        private

        override :global_id_arguments
        def global_id_arguments
          super + %i[iteration_id]
        end

        override :param_mappings
        def param_mappings
          super.merge(iteration_id: :sprint_id)
        end
      end
    end
  end
end
