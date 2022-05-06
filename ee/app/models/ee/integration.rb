# frozen_string_literal: true

module EE
  module Integration
    extend ActiveSupport::Concern

    prepended do
      scope :vulnerability_hooks, -> { where(vulnerability_events: true, active: true) }
    end

    EE_PROJECT_SPECIFIC_INTEGRATION_NAMES = %w[
      github
      gitlab_slack_application
    ].freeze

    EE_SAAS_ONLY_INTEGRATION_NAMES = %w[
      gitlab_slack_application
    ].freeze

    class_methods do
      extend ::Gitlab::Utils::Override

      override :project_specific_integration_names
      def project_specific_integration_names
        super + EE_PROJECT_SPECIFIC_INTEGRATION_NAMES
      end

      def saas_only_integration_names
        EE_SAAS_ONLY_INTEGRATION_NAMES
      end

      override :available_integration_names
      def available_integration_names(...)
        names = super
        names -= saas_only_integration_names unless include_saas_only?
        names
      end

      private

      # Returns true if this instance can show SaaS-only integrations.
      def include_saas_only?
        ::Gitlab.dev_or_test_env? || ::Gitlab.com?
      end
    end
  end
end
