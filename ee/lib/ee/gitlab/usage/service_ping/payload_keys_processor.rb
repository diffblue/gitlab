# frozen_string_literal: true

module EE
  module Gitlab
    module Usage
      module ServicePing
        module PayloadKeysProcessor
          extend ActiveSupport::Concern
          extend ::Gitlab::Utils::Override

          # TODO: Provide more generic and robust conditional availability method https://gitlab.com/gitlab-org/gitlab/-/issues/352875
          METRICS_WITH_CONDITIONAL_AVAILABILITY = %w[
            license_md5
            license_sha256
            license_id
            historical_max_users
            licensee
            license_user_count
            license_billable_users
            license_starts_at
            license_expires_at
            license_plan
            license_add_ons
            license_trial
            license_subscription_id
          ].freeze

          override :missing_instrumented_metrics_key_paths
          def missing_instrumented_metrics_key_paths
            @missing_key_paths ||= super - METRICS_WITH_CONDITIONAL_AVAILABILITY
          end
        end
      end
    end
  end
end
