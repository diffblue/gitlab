# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Update
      class UpdateProcessor
        def process(workspace:, params:)
          if workspace.update(params)
            payload = { workspace: workspace }
            [payload, nil]
          else
            err_msg = "Error(s) updating Workspace: #{workspace.errors.full_messages.join(', ')}"
            error = Error.new(message: err_msg, reason: :bad_request)
            [nil, error]
          end
        end
      end
    end
  end
end
