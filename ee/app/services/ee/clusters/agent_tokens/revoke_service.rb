# frozen_string_literal: true

module EE
  module Clusters
    module AgentTokens
      module RevokeService
        def execute
          super.tap do |response|
            send_audit_event(token, response)
          end
        end

        private

        def send_audit_event(token, response)
          return unless token

          message = if response.success?
                      "Revoked cluster agent token '#{token.name}' with id #{token.id}"
                    else
                      "Attempted to revoke cluster agent token '#{token.name}' with " \
                        "id #{token.id} but failed with message: #{response.message}"
                    end

          audit_context = {
            name: 'cluster_agent_token_revoked',
            author: current_user,
            scope: token.agent.project,
            target: token.agent,
            message: message
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
