# frozen_string_literal: true

module EE
  module API
    class GroupBoards < ::API::Base
      include ::API::PaginationParams
      include ::API::BoardsResponses

      prepend EE::API::BoardsResponses # rubocop: disable Cop/InjectEnterpriseEditionModule

      feature_category :team_planning
      urgency :low

      before do
        authenticate!
      end

      helpers do
        def board_parent
          user_group
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a group'
      end

      resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        segment ':id/boards' do
          desc 'Create a group board' do
            detail 'This feature was introduced in 10.4'
            success ::API::Entities::Board
          end
          params do
            requires :name, type: String, desc: 'The board name'
          end
          post '/' do
            authorize!(:admin_issue_board, board_parent)

            create_board
          end

          desc 'Delete a group board' do
            detail 'This feature was introduced in 10.4'
            success ::API::Entities::Board
          end
          delete '/:board_id' do
            authorize!(:admin_issue_board, board_parent)

            delete_board
          end
        end
      end
    end
  end
end
