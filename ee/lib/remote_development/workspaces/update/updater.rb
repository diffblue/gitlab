# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Update
      class Updater
        include Messages

        # @param [Hash] value
        # @return [Result]
        def self.update(value)
          value => { workspace: RemoteDevelopment::Workspace => workspace, params: Hash => params }
          if workspace.update(params)
            Result.ok(WorkspaceUpdateSuccessful.new({ workspace: workspace }))
          else
            Result.err(WorkspaceUpdateFailed.new({ errors: workspace.errors }))
          end
        end
      end
    end
  end
end
