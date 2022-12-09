# frozen_string_literal: true

require "spec_helper"

RSpec.describe EE::WorkItemsHelper, feature_category: :team_planning do
  describe '#work_items_index_data' do
    subject(:work_items_index_data) { helper.work_items_index_data(project) }

    before do
      stub_licensed_features(
        issuable_health_status: feature_available,
        iterations: feature_available,
        issue_weights: feature_available,
        okrs: feature_available
      )
    end

    let_it_be(:project) { build(:project) }

    context 'when features are available' do
      let(:feature_available) { true }

      it 'returns true for the features' do
        expect(work_items_index_data).to include(
          {
            has_issuable_health_status_feature: "true",
            has_issue_weights_feature: "true",
            has_iterations_feature: "true",
            has_okrs_feature: "true"
          }
        )
      end
    end

    context 'when feature not available' do
      let(:feature_available) { false }

      it 'returns false for the features' do
        expect(work_items_index_data).to include(
          {
            has_issuable_health_status_feature: "false",
            has_issue_weights_feature: "false",
            has_iterations_feature: "false",
            has_okrs_feature: "false"
          }
        )
      end
    end
  end
end
