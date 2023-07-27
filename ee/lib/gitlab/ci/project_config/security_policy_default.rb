# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class SecurityPolicyDefault < Gitlab::Ci::ProjectConfig::Source
        def content
          return unless @project.licensed_feature_available?(:security_orchestration_policies)
          return unless security_policies_enforced?

          # We merge the security scans with the pipeline configuration in ee/lib/ee/gitlab/ci/config_ee.rb.
          # An empty config with no content is enough to trigger the merge process when the Auto DevOps is disabled
          # and no .gitlab-ci.yml is present.
          YAML.dump(nil)
        end
        strong_memoize_attr :content

        def source
          :security_policies_default_source
        end

        private

        def security_policies_enforced?
          ::Feature.enabled?(:scan_execution_policy_pipelines, @project) && active_scan_execution_policies?
        end

        def active_scan_execution_policies?
          ::Gitlab::Security::Orchestration::ProjectPolicyConfigurations
            .new(@project).all
            .to_a
            .flat_map(&:active_scan_execution_policies_for_pipelines)
            .any?
        end
      end
    end
  end
end
