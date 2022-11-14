# frozen_string_literal: true

module API
  class GroupRepositoryStorageMoves < ::API::Base
    include PaginationParams

    before { authenticated_as_admin! }

    feature_category :gitaly

    resource :group_repository_storage_moves do
      desc 'Get a list of all group repository storage moves' do
        detail 'This feature was introduced in GitLab 13.9.'
        is_array true
        success code: 200, model: Entities::Groups::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      get do
        storage_moves = ::Groups::RepositoryStorageMove.with_groups.order_created_at_desc

        present paginate(storage_moves), with: Entities::Groups::RepositoryStorageMove, current_user: current_user
      end

      desc 'Get a group repository storage move' do
        detail 'This feature was introduced in GitLab 13.9.'
        success code: 200, model: Entities::Groups::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a group repository storage move'
      end
      get ':repository_storage_move_id' do
        storage_move = ::Groups::RepositoryStorageMove.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Groups::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule bulk group repository storage moves' do
        detail 'This feature was introduced in GitLab 13.9.'
        success code: 202
      end
      params do
        requires :source_storage_name, type: String, desc: 'The source storage shard', values: -> { Gitlab.config.repositories.storages.keys }
        optional :destination_storage_name, type: String, desc: 'The destination storage shard', values: -> { Gitlab.config.repositories.storages.keys }
      end
      post do
        ::Groups::ScheduleBulkRepositoryShardMovesService.enqueue(
          declared_params[:source_storage_name],
          declared_params[:destination_storage_name]
        )

        accepted!
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of all group repository storage moves' do
        detail 'This feature was introduced in GitLab 13.9.'
        is_array true
        success code: 200, model: Entities::Groups::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      get ':id/repository_storage_moves' do
        storage_moves = user_group.repository_storage_moves.with_groups.order_created_at_desc

        present paginate(storage_moves), with: Entities::Groups::RepositoryStorageMove, current_user: current_user
      end

      desc 'Get a group repository storage move' do
        detail 'This feature was introduced in GitLab 13.9.'
        success code: 200, model: Entities::Groups::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a group repository storage move'
      end
      get ':id/repository_storage_moves/:repository_storage_move_id' do
        storage_move = user_group.repository_storage_moves.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Groups::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule a group repository storage move' do
        detail 'This feature was introduced in GitLab 13.9.'
        success code: 201, model: Entities::Groups::RepositoryStorageMove
      end
      params do
        optional :destination_storage_name, type: String, desc: 'The destination storage shard'
      end
      post ':id/repository_storage_moves' do
        storage_move = user_group.repository_storage_moves.build(
          declared_params.compact.merge(source_storage_name: user_group.wiki.repository_storage)
        )

        if storage_move.schedule
          present storage_move, with: Entities::Groups::RepositoryStorageMove, current_user: current_user
        else
          render_validation_error!(storage_move)
        end
      end
    end
  end
end
