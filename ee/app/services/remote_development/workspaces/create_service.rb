# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    class CreateService
      attr_reader :current_user

      # NOTE: This constructor intentionally does not follow all of the conventions from
      #       https://docs.gitlab.com/ee/development/reusing_abstractions.html#service-classes
      #       suggesting that the dependencies be passed via the constructor.
      #
      #       See "Stateless Service layer classes" in ee/lib/remote_development/README.md for more details.

      # @param [User] current_user
      # @return [void]
      def initialize(current_user:)
        @current_user = current_user
      end

      # noinspection RubyNilAnalysis,RubyResolve
      # @param [Hash] params
      # @return [ServiceResponse]
      def execute(params:)
        project = params[:project]
        return ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized) unless authorized?(project)

        payload, error = RemoteDevelopment::Workspaces::Create::CreateProcessor.new.process(params: params)

        if error
          ServiceResponse.error(message: error.message, reason: error.reason)
        else
          ServiceResponse.success(payload: payload)
        end
      end

      private

      # @param [Project] project
      # @return [TrueClass, FalseClass]
      def authorized?(project)
        current_user&.can?(:create_workspace, project)
      end
    end
  end
end
