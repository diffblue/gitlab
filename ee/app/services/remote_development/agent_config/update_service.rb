# frozen_string_literal: true

module RemoteDevelopment
  module AgentConfig
    class UpdateService
      def execute(agent:, config:)
        # NOTE: We rely on the authentication from the internal kubernetes endpoint and kas so we don't do any
        #       additional authorization checks here.
        #       See https://gitlab.com/gitlab-org/gitlab/-/issues/409038

        if License.feature_available?(:remote_development)
          payload, error = RemoteDevelopment::AgentConfig::UpdateProcessor.new.process(agent: agent, config: config)
        else
          error = "'remote_development' licensed feature is not available"
        end

        # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461
        #       The other existing service called from the `internal/kubernetes/agent_configuration` API endpoint
        #       (::Clusters::Agents::RefreshAuthorizationService) does not use ServiceResponse, it just returns a
        #       boolean value. So we do the same (return the payload, which is truthy) for consistency.
        #       The `internal/kubernetes/agent_configuration` endpoint explictly returns
        #       `no_content!` regardless of the return value, so it wouldn't matter what we returned anyway.
        #       We _don't_ want to change this behavior for now or return an exception in the case of failure,
        #       because that could potentially interfere with the existing behavior of the endpoint, which is
        #       to execute ::Clusters::Agents::RefreshAuthorizationService. So, it's safer to just silently fail to
        #       save the record, log an error, return a boolean for now. We should look into fixing this properly as
        #       part of https://gitlab.com/gitlab-org/gitlab/-/issues/402718 or another error handling issue.
        #
        #       Note that we have abstracted this logic to our domain-layer tier in `lib/remote_development`,
        #       with our standard `[payload, RemoteDevelopment::Error]` tuple return value,
        #       so that abstracts us somewhat from whatever we decide to do with this error handling at the Service
        #       layer.
        #
        #       Also note that currently, this will always be expected to fail if `enabled: false` is specified, because
        #       for the initial release, we are enforcing that all config attributes (including `enabled`) are
        #       immutable, and thus enabled must be set to true upon creation.

        return false if error

        payload
      end
    end
  end
end
