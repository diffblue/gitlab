# frozen_string_literal: true

module EE
  module ArchivedAbilities
    extend ActiveSupport::Concern

    ARCHIVED_ABILITIES_EE = %i[
      admin_software_license_policy
      modify_auto_fix_setting
      create_test_case
    ].freeze

    ARCHIVED_FEATURES_EE = %i[
      issue_board
      issue_link
      approvers
      vulnerability_feedback
      vulnerability
      feature_flag
      feature_flags_client
      iteration
    ].freeze

    class_methods do
      extend ::Gitlab::Utils::Override

      override :archived_abilities
      def archived_abilities
        (super + ARCHIVED_ABILITIES_EE).freeze
      end

      override :archived_features
      def archived_features
        (super + ARCHIVED_FEATURES_EE).freeze
      end
    end
  end
end
