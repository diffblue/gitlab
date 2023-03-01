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

          argument :epic_id, ::Types::GlobalIDType[::Epic],
            required: false,
            description: 'Global ID of the epic that will be assigned to the issues.'

          argument :health_status, ::Types::HealthStatusEnum,
            required: false,
            description: 'Health status that will be assigned to the issues.'
        end

        private

        override :global_id_arguments
        def global_id_arguments
          super + %i[iteration_id epic_id]
        end

        override :param_mappings
        def param_mappings
          super.merge(iteration_id: :sprint_id)
        end

        override :find_parent!
        def find_parent!(parent_id)
          parent = super
          return parent unless parent.is_a?(::Group)

          raise_resource_not_available_error! unless parent.licensed_feature_available?(:group_bulk_edit)

          parent
        end
      end
    end
  end
end
