# frozen_string_literal: true

module EE
  module IssueAvailableFeatures
    extend ActiveSupport::Concern

    class_methods do
      include ::Gitlab::Utils::StrongMemoize
      extend ::Gitlab::Utils::Override

      override :available_features_for_issue_types
      def available_features_for_issue_types
        strong_memoize(:available_features_for_issue_types) do
          super.tap do |available_features|
            available_features[:epics] = %w(issue)
            available_features[:sla] = %w(incident)
            available_features[:confidentiality] += %w(test_case)
            available_features[:move_and_clone] += %w(test_case)
          end
        end
      end
    end
  end
end
