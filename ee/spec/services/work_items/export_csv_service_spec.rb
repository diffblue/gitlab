# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ExportCsvService, :with_license, feature_category: :team_planning do
  # TODO - once we have a UI for this feature
  # we can turn these into feature specs.
  # more info at: https://gitlab.com/gitlab-org/gitlab/-/issues/396943
  context 'when importing an exported file' do
    context 'for work item of type requirement' do
      before do
        stub_licensed_features(requirements: true)
      end

      it_behaves_like 'a exported file that can be imported' do
        let_it_be(:user) { create(:user) }
        let_it_be(:origin_project) { create(:project) }
        let_it_be(:target_project) { create(:project) }
        let_it_be(:work_item) { create(:work_item, :requirement, project: origin_project) }

        let(:expected_matching_fields) { %w[title work_item_type] }
      end
    end
  end
end
