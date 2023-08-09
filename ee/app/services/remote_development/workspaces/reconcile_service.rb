# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    class ReconcileService
      include ServiceResponseFactory

      # NOTE: This constructor intentionally does not follow all of the conventions from
      #       https://docs.gitlab.com/ee/development/reusing_abstractions.html#service-classes
      #       suggesting that the dependencies be passed via the constructor.
      #
      #       See "Stateless Service layer classes" in ee/lib/remote_development/README.md for more details.

      # @param [Clusters::Agent] agent
      # @param [Hash] params
      # @return [ServiceResponse]
      def execute(agent:, params:)
        # NOTE: We rely on the authentication from the internal kubernetes endpoint and kas so we don't do any
        #       additional authorization checks here.
        #       See https://gitlab.com/gitlab-org/gitlab/-/issues/409038

        # NOTE: We inject these dependencies which depend upon the main Rails monolith, so that the domain layer
        #       does not directly depend on them, and also so that we can use fast_spec_helper in more places.
        logger = RemoteDevelopment::Logger.build

        response_hash = Reconcile::Main.main(
          # NOTE: We pass the original params in a separate key, so they can be separately and independently validated
          #       against a JSON schema, then flattened and converted to have symbol keys instead of string keys.
          #       We do not want to do any direct processing or manipulation of them here in the service layer,
          #       because that would be introducing domain logic into the service layer and coupling it to the
          #       shape and contents of the params payload.
          original_params: params,
          agent: agent,
          logger: logger
        )

        # Type-check payload using rightward assignment
        response_hash[:payload] => { workspace_rails_infos: Array } if response_hash[:payload]

        create_service_response(response_hash)
      end
    end
  end
end
