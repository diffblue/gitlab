# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class Authorizer
        include Messages

        # @param [Hash] value
        # @return [Result]
        def self.authorize(value)
          value => { current_user: User => current_user, params: Hash => params }
          params => { project: Project => project }

          if current_user.can?(:create_workspace, project)
            Result.ok(value)
          else
            Result.err(Unauthorized.new)
          end
        end
      end
    end
  end
end
