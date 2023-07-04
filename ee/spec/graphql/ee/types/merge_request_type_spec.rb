# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequest'], feature_category: :code_review_workflow do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_fields(:approvals_required, :merge_trains_count, :approval_state, :finding_reports_comparer).at_least }
  it { expect(described_class).to have_graphql_field(:approved, complexity: 2, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:approvals_left, complexity: 2, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:has_security_reports, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:security_reports_up_to_date_on_target_branch, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:suggested_reviewers) }
  it { expect(described_class).to have_graphql_field(:diff_llm_summaries) }

  describe '#merge_trains_count', feature_category: :merge_trains do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:merge_request) { create(:merge_request, :with_merged_metrics, target_project: project, source_project: project) }
    let_it_be(:current_user) { create :admin }

    subject(:resulting_count) { resolve_field(:merge_trains_count, merge_request, current_user: current_user) }

    context 'when merge trains are disabled' do
      it 'the count is null' do
        expect(resulting_count).to be_nil
      end
    end

    context 'when merge trains are enabled' do
      before do
        allow(project).to receive(:merge_trains_enabled?).and_return(true)
      end

      it 'gets the count' do
        expect(resulting_count).to be_zero
      end
    end
  end
end
