# frozen_string_literal: true

module EE
  module Mutations
    module Boards
      module Issues
        module IssueMoveList
          extend ActiveSupport::Concern
          extend ::Gitlab::Utils::Override

          EpicID = ::Types::GlobalIDType[::Epic]

          prepended do
            argument :epic_id, EpicID,
                      required: false,
                      description: 'ID of the parent epic. NULL when removing the association.'
          end

          override :move_issue
          def move_issue(board, issue, move_params)
            super
          rescue ::Issues::BaseService::EpicAssignmentError => e
            ServiceResponse.error(message: e.message)
          rescue ::Gitlab::Access::AccessDeniedError
            ServiceResponse.error(message: 'You are not allowed to move the issue')
          rescue ActiveRecord::RecordNotFound
            ServiceResponse.error(message: 'Resource not found')
          end

          override :move_arguments
          def move_arguments(args)
            epic_arguments = args.slice(:epic_id).transform_values { |id| id&.model_id }

            super.merge!(epic_arguments)
          end
        end
      end
    end
  end
end
