# frozen_string_literal: true

module EE
  module Integration
    extend ActiveSupport::Concern

    prepended do
      scope :vulnerability_hooks, -> { where(vulnerability_events: true, active: true) }
    end

    EE_PROJECT_SPECIFIC_INTEGRATION_NAMES = %w[
      github
    ].freeze

    class_methods do
      extend ::Gitlab::Utils::Override

      override :project_specific_integration_names
      def project_specific_integration_names
        super + EE_PROJECT_SPECIFIC_INTEGRATION_NAMES
      end
    end
  end
end
