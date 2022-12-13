# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Analytics::CodeReviewAnalytics, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, namespace: group) }
  let(:current_user) { reporter }

  let_it_be(:reporter) do
    create(:user).tap { |u| project.add_reporter(u) }
  end

  let_it_be(:guest) do
    create(:user).tap { |u| project.add_guest(u) }
  end

  describe 'GET code_review' do
    subject(:api_call) do
      get api("/analytics/code_review?#{query_params.to_query}", current_user)
    end

    let(:query_params) { { project_id: project.id } }

    it 'is successful' do
      api_call

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with merge requests present' do
      let_it_be(:label) { create :label, project: project }
      let_it_be(:milestone) { create :milestone, project: project }

      let!(:merge_request_1) { create(:merge_request, :opened, source_project: project, target_branch: 'mr1') }
      let!(:merge_request_2) { create(:labeled_merge_request, :opened, source_project: project, labels: [label], target_branch: 'mr2') }
      let!(:merge_request_3) { create(:labeled_merge_request, :opened, source_project: project, labels: [label], milestone: milestone, target_branch: 'mr3') }
      let!(:closed_merge_request) { create(:merge_request, :closed, source_project: project, target_branch: 'mr4') }
      let!(:merged_merge_request) { create(:merge_request, :merged, source_project: project, target_branch: 'mr5') }

      it 'returns list of open MRs with pagination headers' do
        api_call

        expect(json_response.map { |mr| mr['id'] }).to match_array([merge_request_1.id, merge_request_2.id, merge_request_3.id])
        expect(json_response.first.keys)
          .to include(*%w[id iid web_url created_at milestone review_time author approved_by notes_count diff_stats])
        expect(response.headers).to include(*%w[X-Per-Page X-Page X-Next-Page X-Prev-Page X-Total X-Total-Pages])
      end

      context 'with label & milestone filters' do
        let(:query_params) { super().merge(label_name: [label.title], milestone_title: milestone.title) }

        it 'applies filter' do
          api_call

          expect(json_response.map { |mr| mr['id'] }).to match_array([merge_request_3.id])
        end
      end

      context 'with negation filters' do
        let(:query_params) { super().merge(not: { label_name: [label.title] }) }

        it 'applies filter' do
          api_call

          expect(json_response.map { |mr| mr['id'] }).to match_array([merge_request_1.id])
        end
      end

      context 'with any label filter present' do
        let(:query_params) { super().merge(label_name: ['Any']) }

        it 'applies filter' do
          api_call

          expect(json_response.map { |mr| mr['id'] }).to match_array([merge_request_2.id, merge_request_3.id])
        end
      end
    end

    context 'when user has no authorization' do
      let(:current_user) { guest }

      it 'is not authorized' do
        api_call

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when feature is not available in plan' do
      before do
        stub_licensed_features(code_review_analytics: false)
      end

      it 'is not_authorized' do
        api_call

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when project_id is not specified' do
      subject(:api_call) { get api("/analytics/code_review", current_user) }

      it 'is not found' do
        api_call

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
