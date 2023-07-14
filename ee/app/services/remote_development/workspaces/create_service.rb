# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    class CreateService
      include ServiceResponseFactory

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

      # @param [Hash] params
      # @return [ServiceResponse]
      def execute(params:)
        response_hash = Create::Main.main(current_user: current_user, params: params)

        # Type-check payload using rightward assignment
        response_hash[:payload] => { workspace: Workspace } if response_hash[:payload]

        create_service_response(response_hash)
      end
    end
  end
end
