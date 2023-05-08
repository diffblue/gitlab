# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    class ReconcileService
      # NOTE: This class intentionally does not follow the constructor conventions from
      #       https://docs.gitlab.com/ee/development/reusing_abstractions.html#service-classes
      #       suggesting that the dependencies be passed via the constructor. This is because
      #       the RemoteDevelopment feature architecture follows a more pure-functional style,
      #       directly in method calls rather than via constructor. We also don't use any of the
      #       provided superclasses like BaseContainerService or its descendants, because all of the
      #       domain logic is isolated and decoupled to the architectural tier below this,
      #       i.e. in the `*Processor` classes, and therefore these superclasses provide nothing
      #       of use. In this case we also do not even pass the `current_user:` parameter, because this
      #       service is called from GA4K kas from an internal kubernetes endpoint, and thus there
      #       is no current_user in context. Therefore we have no need for a constructor at all.
      #
      #       See https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/remote-development-feature-architectural-standards.md
      #       for more discussion on this topic.

      def execute(agent:, params:)
        # NOTE: We rely on the authentication from the internal kubernetes endpoint and kas so we don't do any
        #       additional authorization checks here.
        #       See https://gitlab.com/gitlab-org/gitlab/-/issues/409038

        # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461
        #       We need to perform all processing in an explicit transaction, so that any unexpected exceptions will
        #       cause the transaction to be rolled back. This might not be necessary if we weren't having to rescue
        #       all exceptions below due to another problem. See the to do comment below in rescue clause for more info
        ApplicationRecord.transaction do
          process(agent, params)
        end
      rescue => e # rubocop:disable Style:RescueStandardError
        # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461
        #       If anything in the service class throws an exception, it ends up calling
        #       #handle_api_exception, in lib/api/helpers.rb, which tries to get current_user,
        #       which ends up calling API::Helpers#unauthorized! in lib/api/helpers.rb,
        #       when ends up setting @current_user to a Rack::Response, which blows up later
        #       in API::Helpers#current_user (lib/api/helpers.rb#79), when we try to get
        #       #preferred_language off of it.
        #       So we have to catch all exceptions and handle as a ServiceResponse.error
        #       in order to avoid this.
        #       How do the other ga4k requests like starboard_vulnerability handle this?
        #       UPDATE: See more context in https://gitlab.com/gitlab-org/gitlab/-/issues/402718#note_1343933650

        Gitlab::ErrorTracking.track_exception(e, error_type: 'reconcile', agent_id: agent.id)
        ServiceResponse.error(
          message: "Unexpected reconcile error. Exception class: #{e.class}.",
          reason: :internal_server_error
        )
      end

      private

      def process(agent, params)
        parsed_params, error = RemoteDevelopment::Workspaces::Reconcile::ParamsParser.new.parse(params: params)
        return ServiceResponse.error(message: error.message, reason: error.reason) if error

        reconcile_processor = Reconcile::ReconcileProcessor.new
        payload, error = reconcile_processor.process(agent: agent, **parsed_params)

        return ServiceResponse.error(message: error.message, reason: error.reason) if error

        ServiceResponse.success(payload: payload)
      end
    end
  end
end
