# frozen_string_literal: true

module EE
  module ReadonlyAbilities
    extend ActiveSupport::Concern

    READONLY_ABILITIES = %i[
      admin_tag
      push_to_delete_protected_branch
      create_merge_request_from
      create_merge_request_in
      admin_software_license_policy
      modify_auto_fix_setting
      create_test_case
      create_package
    ].freeze

    READONLY_FEATURES = %i[
      merge_request
      snippet
      wiki
      pipeline
      pipeline_schedule
      build
      trigger
      environment
      deployment
      commit_status
      container_image
      cluster
      release
      approvers
      vulnerability_feedback
      vulnerability
      feature_flag
      feature_flags_client
      iteration
    ].freeze

    class_methods do
      def readonly_abilities
        READONLY_ABILITIES
      end

      def readonly_features
        READONLY_FEATURES
      end
    end
  end
end
