# frozen_string_literal: true

module EE
  module Mutations
    module Issues
      module Update
        extend ActiveSupport::Concern

        prepended do
          include ::Mutations::Issues::CommonEEMutationArguments

          argument :epic_id, ::Types::GlobalIDType[::Epic],
                   required: false,
                   loads: ::Types::EpicType,
                   description: 'ID of the parent epic. NULL when removing the association.'
        end

        def resolve(**args)
          super
        rescue ::Gitlab::Access::AccessDeniedError
          raise_resource_not_available_error!
        end
      end
    end
  end
end
