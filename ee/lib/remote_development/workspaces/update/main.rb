# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Update
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
              .and_then(Authorizer.method(:authorize))
              .and_then(Updater.method(:update))

          case result
          in { err: Unauthorized => message }
            generate_error_response_from_message(message: message, reason: :unauthorized)
          in { err: WorkspaceUpdateFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { ok: WorkspaceUpdateSuccessful => message }
            { status: :success, payload: message.context }
          else
            raise UnmatchedResultError.new(result: result)
          end
        end
      end
    end
  end
end
