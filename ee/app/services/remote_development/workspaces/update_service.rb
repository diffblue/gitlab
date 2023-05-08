# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    class UpdateService
      attr_reader :current_user

      # NOTE: This constructor intentionally does not follow all of the conventions from
      #       https://docs.gitlab.com/ee/development/reusing_abstractions.html#service-classes
      #       suggesting that the dependencies be passed via the constructor. This is because
      #       the RemoteDevelopment feature architecture follows a more pure-functional style,
      #       by avoiding instance variables and instance state and preferring to pass data
      #       directly in method calls rather than via constructor. We also don't use any of the
      #       provided superclasses like BaseContainerService or its descendants, because all of the
      #       domain logic is isolated and decoupled to the architectural tier below this,
      #       i.e. in the `*Processor` classes, and therefore these superclasses provide nothing
      #       of use. However, we do still conform to the convention of passing the current_user
      #       in the constructor, since this convention is related to security, and worth following
      #       the existing patterns and principle of least surprise.
      #
      #       See https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/remote-development-feature-architectural-standards.md
      #       for more discussion on this topic.
      def initialize(current_user:)
        @current_user = current_user
      end

      def execute(workspace:, params:)
        return ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized) unless authorized?(workspace)

        payload, error = RemoteDevelopment::Workspaces::Update::UpdateProcessor.new.process(
          workspace: workspace,
          params: params
        )

        return ServiceResponse.error(message: error.message, reason: error.reason) if error

        ServiceResponse.success(payload: payload)
      end

      def authorized?(workspace)
        current_user&.can?(:update_workspace, workspace)
      end
    end
  end
end
