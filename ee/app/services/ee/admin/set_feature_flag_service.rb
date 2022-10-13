# frozen_string_literal: true

module EE
  module Admin
    module SetFeatureFlagService
      extend ::Gitlab::Utils::Override

      override :validate_feature_flag_name
      def validate_feature_flag_name
        super

        return unless GitlabSubscriptions::Features::PLANS_BY_FEATURE[name.to_sym]

        "The '#{name}' is a licensed feature name, " \
        "and thus it cannot be used as a feature flag name. " \
        "Use `rails console` to set this feature flag state."
      end
    end
  end
end
