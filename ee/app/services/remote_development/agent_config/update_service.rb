# frozen_string_literal: true

module RemoteDevelopment
  module AgentConfig
    class UpdateService
      include ServiceResponseFactory

      # NOTE: This constructor intentionally does not follow all of the conventions from
      #       https://docs.gitlab.com/ee/development/reusing_abstractions.html#service-classes
      #       suggesting that the dependencies be passed via the constructor.
      #
      #       See "Stateless Service layer classes" in ee/lib/remote_development/README.md for more details.

      # @param [Clusters::Agent] agent
      # @param [Hash] config
      # @return [ServiceResponse]
      def execute(agent:, config:)
        # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461
        #       The other existing service called from the `internal/kubernetes/agent_configuration` API endpoint
        #       (::Clusters::Agents::RefreshAuthorizationService) does not use ServiceResponse, it just returns a
        #       boolean value. So we do the same (return the ServiceResponse, which is truthy) for consistency,
        #       even though the return value is ignored, and not even checked for errors.
        #       The `internal/kubernetes/agent_configuration` endpoint explictly returns
        #       `no_content!` regardless of the return value, so it wouldn't matter what we returned anyway.
        #       We _don't_ want to change this behavior for now or return an exception in the case of failure,
        #       because that could potentially interfere with the existing behavior of the endpoint, which is
        #       to execute ::Clusters::Agents::RefreshAuthorizationService. So, it's safer to just silently fail to
        #       save the record, log an error, return a boolean for now. We should look into fixing this properly as
        #       part of https://gitlab.com/gitlab-org/gitlab/-/issues/402718 or another error handling issue.
        #
        #       Note that we have abstracted this logic to our domain-layer tier in `lib/remote_development`,
        #       and still attempt to return an appropriate ServiceResponse object, even though it is ignored,
        #       so that abstracts us somewhat from whatever we decide to do with this error handling at the Service
        #       layer.
        response_hash = Main.main(agent: agent, config: config)

        # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461 - Add at least some logging here.
        create_service_response(response_hash)
      end
    end
  end
end
