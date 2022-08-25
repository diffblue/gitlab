# frozen_string_literal: true

module EE
  module EnvironmentSerializer
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :environment_associations
    def environment_associations
      super.deep_merge(latest_opened_most_severe_alert: [])
    end

    override :deployment_associations
    def deployment_associations
      super.deep_merge(approvals: {
        user: []
      })
    end

    override :project_associations
    def project_associations
      super.deep_merge(protected_environments: [])
    end

    override :batch_load
    def batch_load(resource)
      environments = super

      ::Preloaders::Environments::ProtectedEnvironmentPreloader.new(environments).execute(association_attributes)

      environments.each do |environment|
        # JobEntity loads environment for permission checks in #cancelable?, #retryable?, #playable?
        environment.last_deployment&.deployable&.persisted_environment = environment
        environment.upcoming_deployment&.deployable&.persisted_environment = environment
      end
    end

    def association_attributes
      [:deploy_access_levels, :project]
    end
  end
end
