# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssueFeatureFlagsController, feature_category: :feature_flags do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  before do
    stub_licensed_features(feature_flags_related_issues: true)
  end

  describe 'GET #index' do
    def setup
      feature_flag = create(:operations_feature_flag, project: project)
      issue = create(:issue, project: project)
      link = create(:feature_flag_issue, feature_flag: feature_flag, issue: issue)

      [feature_flag, issue, link]
    end

    def get_request(project, issue)
      get project_issue_feature_flags_path(project, issue, format: :json)
    end

    it 'returns linked feature flags' do
      feature_flag, issue = setup
      sign_in(developer)

      get_request(project, issue)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match([a_hash_including({
        'id' => feature_flag.id
      })])
    end

    it 'does not return linked feature flags for a reporter' do
      _, issue, _ = setup
      sign_in(reporter)

      get_request(project, issue)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'orders by feature_flag_issue id' do
      issue = create(:issue, project: project)
      feature_flag_a = create(:operations_feature_flag, project: project)
      feature_flag_b = create(:operations_feature_flag, project: project)
      create(:feature_flag_issue, feature_flag: feature_flag_b, issue: issue)
      create(:feature_flag_issue, feature_flag: feature_flag_a, issue: issue)
      sign_in(developer)

      get_request(project, issue)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.map { |feature_flag| feature_flag['id'] }).to eq([feature_flag_b.id, feature_flag_a.id])
    end

    it 'does not make N+1 queries' do
      feature_flag, _, _ = setup
      sign_in(developer)

      control_count = ActiveRecord::QueryRecorder.new { get_request(project, feature_flag) }.count

      issue_b = create(:issue, project: project)
      issue_c = create(:issue, project: project)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_b)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_c)

      expect { get_request(project, feature_flag) }.not_to exceed_query_limit(control_count)
    end

    context 'when feature flag related issues feature is unlicensed' do
      before do
        stub_licensed_features(feature_flags_related_issues: false)
      end

      it 'returns not found' do
        feature_flag, _, _ = setup
        sign_in(developer)

        get_request(project, feature_flag)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
