# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class OperationalVulnerabilitiesConfigurationService
      include Gitlab::Utils::StrongMemoize

      def initialize(agent)
        @agent = agent
      end

      def execute
        applicable_configurations
          .compact
      end

      private

      attr_reader :agent

      delegate :project, to: :agent

      def applicable_configurations
        policies.flat_map do |policy|
          next unless policy[:enabled]

          policy[:rules].map do |rule|
            next unless rule_applicable_for_agent?(rule)

            {
              config: policy[:config],
              cadence: rule[:cadence],
              namespaces: Array.wrap(rule.dig(:agents, agent.name.to_sym, :namespaces))
            }
          end
        end
      end

      def rule_applicable_for_agent?(rule)
        rule[:type] == Security::ScanExecutionPolicy::RULE_TYPES[:schedule] && rule[:agents]&.key?(agent.name.to_sym)
      end

      def policies
        strong_memoize(:policies) do
          ::Security::ScanExecutionPoliciesFinder
            .new(
              agent,
              project,
              action_scan_types: %i[container_scanning cluster_image_scanning],
              relationship: :inherited
            ).execute
        end
      end
    end
  end
end
