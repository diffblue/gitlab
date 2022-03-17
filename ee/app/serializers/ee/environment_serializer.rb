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
  end
end
