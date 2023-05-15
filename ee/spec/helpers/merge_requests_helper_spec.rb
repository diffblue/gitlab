# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::MergeRequestsHelper, feature_category: :code_review_workflow do
  include Users::CalloutsHelper
  include ApplicationHelper
  include PageLayoutHelper
  include ProjectsHelper

  describe '#render_items_list' do
    it "returns one item in the list" do
      expect(render_items_list(["user"])).to eq("user")
    end

    it "returns two items in the list" do
      expect(render_items_list(%w(user user1))).to eq("user and user1")
    end

    it "returns three items in the list" do
      expect(render_items_list(%w(user user1 user2))).to eq("user, user1 and user2")
    end
  end

  describe '#diffs_tab_pane_data' do
    subject(:diffs_tab_pane_data) { helper.diffs_tab_pane_data(project, merge_request, {}) }

    let_it_be(:current_user) { build_stubbed(:user) }
    let_it_be(:project) { build_stubbed(:project) }
    let_it_be(:merge_request) { build_stubbed(:merge_request, project: project) }

    before do
      project.add_developer(current_user)

      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'for show_generate_test_file_button' do
      it 'returns expected value' do
        expect(subject[:show_generate_test_file_button]).to eq('false')
      end
    end

    context 'for endpoint_codequality' do
      before do
        stub_licensed_features(inline_codequality: true)

        allow(merge_request).to receive(:has_codequality_mr_diff_report?).and_return(true)
      end

      it 'returns expected value' do
        expect(
          subject[:endpoint_codequality]
        ).to eq("/#{project.full_path}/-/merge_requests/#{merge_request.iid}/codequality_mr_diff_reports.json")
      end
    end

    context 'for endpoint_sast' do
      before do
        allow(merge_request).to receive(:has_sast_reports?).and_return(true)
      end

      it 'returns expected value' do
        expect(
          subject[:endpoint_sast]
        ).to eq("/#{project.full_path}/-/merge_requests/#{merge_request.iid}/security_reports?type=sast")
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(sast_reports_in_inline_diff: false)
        end

        it 'does not return endpoint' do
          expect(subject).not_to have_key(:endpoint_sast)
        end
      end
    end
  end
end
