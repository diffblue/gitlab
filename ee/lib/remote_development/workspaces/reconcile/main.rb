# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class Main
        include Messages

        extend MessageSupport
        private_class_method :generate_error_response_from_message

        # @param [Hash] value
        # @return [Hash]
        # @raise [UnmatchedResultError]
        def self.main(value)
          initial_result = Result.ok(value)

          result =
            initial_result
              .and_then(Input::ParamsValidator.method(:validate))
              .map(Input::ParamsExtractor.method(:extract))
              .map(Input::ParamsToInfosConverter.method(:convert))
              .map(Input::AgentInfosObserver.method(:observe))
              .map(Persistence::WorkspacesFromAgentInfosUpdater.method(:update))
              .map(Persistence::OrphanedWorkspacesObserver.method(:observe))
              .map(Persistence::WorkspacesToBeReturnedFinder.method(:find))
              .map(Output::WorkspacesToRailsInfosConverter.method(:convert))
              .map(Persistence::WorkspacesToBeReturnedUpdater.method(:update))
              .map(Output::RailsInfosObserver.method(:observe))
              .map(
                # As the final step, return the workspace_rails_infos in a WorkspaceReconcileSuccessful message
                ->(value) do
                  RemoteDevelopment::Messages::WorkspaceReconcileSuccessful.new(
                    workspace_rails_infos: value.fetch(:workspace_rails_infos)
                  )
                end
              )

          case result
          in { err: WorkspaceReconcileParamsValidationFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { ok: WorkspaceReconcileSuccessful => message }
            message.context => { workspace_rails_infos: Array } # Type-check the payload before returning it
            { status: :success, payload: message.context }
          else
            raise UnmatchedResultError.new(result: result)
          end
        end
      end
    end
  end
end
