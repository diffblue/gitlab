# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
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
              .and_then(DevfileFetcher.method(:fetch))
              .and_then(PreFlattenDevfileValidator.method(:validate))
              .and_then(DevfileFlattener.method(:flatten))
              .and_then(PostFlattenDevfileValidator.method(:validate))
              .map(VolumeDefiner.method(:define))
              .map(VolumeComponentInjector.method(:inject))
              .map(EditorComponentInjector.method(:inject))
              .map(ProjectClonerComponentInjector.method(:inject))
              .and_then(Creator.method(:create))

          # rubocop:disable Lint/DuplicateBranch - Rubocop doesn't know the branches are different due to destructuring
          case result
          in { err: Unauthorized => message }
            generate_error_response_from_message(message: message, reason: :unauthorized)
          in { err: WorkspaceCreateParamsValidationFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { err: WorkspaceCreateDevfileLoadFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { err: WorkspaceCreatePreFlattenDevfileValidationFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { err: WorkspaceCreateDevfileFlattenFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { err: WorkspaceCreatePostFlattenDevfileValidationFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { err: WorkspaceCreateFailed => message }
            generate_error_response_from_message(message: message, reason: :bad_request)
          in { ok: WorkspaceCreateSuccessful => message }
            { status: :success, payload: message.context }
          else
            raise UnmatchedResultError.new(result: result)
          end
          # rubocop:enable Lint/DuplicateBranch
        end
      end
    end
  end
end
