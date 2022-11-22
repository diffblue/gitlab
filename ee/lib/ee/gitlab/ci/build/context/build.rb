# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Build
        module Context
          module Build
            extend ::Gitlab::Utils::Override

            VARIABLE_OVERRIDES = ::Security::SecurityOrchestrationPolicies::ScanPipelineService::SCAN_VARIABLES
                                   .values
                                   .reduce({}, :merge)
                                   .freeze

            override :variables
            def variables
              collection = super

              return collection unless sanitize?

              sanitized_collection(collection)
            end

            private

            def sanitize?
              feature_available? && active_scan_policies?
            end

            def feature_available?
              project&.feature_available?(:security_orchestration_policies)
            end

            def active_scan_policies?
              project
                &.security_orchestration_policy_configuration
                &.active_scan_execution_policies
                &.any?
            end

            def sanitized_collection(collection)
              ::Gitlab::Ci::Variables::Collection.new(
                collection.to_hash.merge(VARIABLE_OVERRIDES).compact.map do |k, v|
                  { key: k, value: v }
                end
              )
            end
          end
        end
      end
    end
  end
end
