# frozen_string_literal: true

module API
  class EpicBoards < ::API::Base
    include PaginationParams

    feature_category :portfolio_management
    urgency :low

    before do
      authenticate!
      authorize_epics_feature!
    end

    helpers ::API::Helpers::EpicsHelpers

    helpers do
      def epic_board
        epic_boards.find(params[:board_id])
      end

      def epic_boards
        ::Boards::EpicBoardsFinder.new(user_group).execute.with_api_entity_associations
      end

      def epic_lists
        epic_board.destroyable_lists.preload_associated_models
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group', documentation: { example: '1' }
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/epic_boards' do
        desc 'Get all group epic boards' do
          detail 'This feature was introduced in 15.9'
          success Entities::EpicBoard
          is_array true
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          use :pagination
        end
        get '/' do
          authorize! :read_epic_board, user_group

          present paginate(epic_boards), with: Entities::EpicBoard
        end

        desc 'Find a group epic board' do
          detail 'This feature was introduced in 15.9'
          success Entities::EpicBoard
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :board_id, type: Integer, desc: 'The ID of an epic board', documentation: { example: 1 }
        end
        get '/:board_id' do
          authorize!(:read_epic_board, user_group)

          present epic_board, with: Entities::EpicBoard
        end
      end

      params do
        requires :board_id, type: Integer, desc: 'The ID of an epic board', documentation: { example: 1 }
      end
      segment ':id/epic_boards/:board_id' do
        desc 'Get the lists of a group epic board' do
          detail 'Does not include backlog and closed lists. This feature was introduced in 15.9'
          success Entities::EpicBoards::List
          is_array true
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          use :pagination
        end
        get '/lists' do
          authorize!(:read_epic_board, epic_board)

          present paginate(epic_lists), with: Entities::EpicBoards::ListDetails
        end

        desc 'Get a list of a group epic board' do
          detail 'This feature was introduced in 15.9'
          success Entities::EpicBoards::List
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a list', documentation: { example: 1 }
        end
        get '/lists/:list_id' do
          authorize!(:read_epic_board, epic_board)

          present epic_lists.find(params[:list_id]), with: Entities::EpicBoards::ListDetails
        end
      end
    end
  end
end
