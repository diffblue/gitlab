# frozen_string_literal: true

module Mutations
  module Projects
    class SetLocked < BaseMutation
      graphql_name 'ProjectSetLocked'

      include FindsProject

      authorize :push_code

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project to mutate.'

      argument :file_path, GraphQL::Types::String,
        required: true,
        description: 'Full path to the file.'

      argument :lock, GraphQL::Types::Boolean,
        required: true,
        description: 'Whether or not to lock the file path.'

      field :project, Types::ProjectType,
        null: true,
        description: 'Project after mutation.'

      attr_reader :project

      def resolve(project_path:, file_path:, lock:)
        @project = authorized_find!(project_path)

        unless allowed?
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'FileLocks feature disabled'
        end

        if lock
          lock_path(file_path)
        else
          unlock_path(file_path)
        end

        {
          project: project,
          errors: []
        }
      rescue PathLocks::UnlockService::AccessDenied => e
        {
          project: nil,
          errors: [e.message]
        }
      end

      private

      delegate :repository, to: :project

      def fetch_path_lock(file_path)
        project.path_locks.find_by(path: file_path) # rubocop: disable CodeReuse/ActiveRecord
      end

      def lock_path(file_path)
        return if fetch_path_lock(file_path)

        path_lock = PathLocks::LockService.new(project, current_user).execute(file_path)

        if path_lock.persisted? && sync_with_lfs?(file_path)
          Lfs::LockFileService.new(project, current_user, path: file_path, create_path_lock: false).execute
        end
      end

      def unlock_path(file_path)
        path_lock = fetch_path_lock(file_path)

        return unless path_lock

        PathLocks::UnlockService.new(project, current_user).execute(path_lock)

        if sync_with_lfs?(file_path)
          Lfs::UnlockFileService.new(project, current_user, path: file_path, force: true).execute
        end
      end

      def sync_with_lfs?(file_path)
        project.lfs_enabled? && lfs_file?(file_path)
      end

      def lfs_file?(file_path)
        blob = repository.blob_at_branch(repository.root_ref, file_path)

        return false unless blob

        lfs_blob_ids = LfsPointersFinder.new(repository, file_path).execute

        lfs_blob_ids.include?(blob.id)
      end

      def allowed?
        project.licensed_feature_available?(:file_locks)
      end
    end
  end
end
