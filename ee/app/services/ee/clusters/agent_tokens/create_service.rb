# frozen_string_literal: true

module EE
  module Clusters
    module AgentTokens
      module CreateService
        def execute
          super.tap do |response|
            send_audit_event(response)
          end
        end

        private

        def send_audit_event(response)
          message = if response.success?
                      "Created cluster agent token '#{response.payload[:token].name}' " \
                        "with id #{response.payload[:token].id}"
                    else
                      "Attempted to create cluster agent token '#{params[:name]}' but " \
                        "failed with message: #{response.message}"
                    end

          audit_context = {
            name: 'cluster_agent_token_created',
            author: current_user,
            scope: agent.project,
            target: agent,
            message: message
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
