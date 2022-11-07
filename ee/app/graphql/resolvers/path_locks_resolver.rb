# frozen_string_literal: true

module Resolvers
  class PathLocksResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead

    authorize :read_code

    type Types::PathLockType, null: true

    alias_method :project, :object

    def resolve_with_lookahead(**args)
      authorize!(project)

      return [] unless path_lock_feature_enabled?

      find_path_locks(args)
    end

    private

    def preloads
      { user: [:user] }
    end

    def find_path_locks(args)
      apply_lookahead(project.path_locks)
    end

    def path_lock_feature_enabled?
      project.licensed_feature_available?(:file_locks)
    end
  end
end
