# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssueLinksController, feature_category: :team_planning do
  let_it_be(:namespace) { create(:group, :public) }
  let_it_be(:project)   { create(:project, :public, namespace: namespace) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue1) { create(:issue, project: project) }
  let_it_be(:issue2) { create(:issue, project: project) }

  describe 'GET #index' do
    let_it_be(:issue_link) { create(:issue_link, source: issue1, target: issue2, link_type: 'blocks') }

    def get_link(user, issue)
      sign_in(user)

      params = {
        namespace_id: issue.project.namespace.to_param,
        project_id: issue.project,
        issue_id: issue.iid
      }

      get :index, params: params, as: :json
    end

    before do
      project.add_developer(user)
    end

    it 'returns success response' do
      get_link(user, issue1)

      expect(response).to have_gitlab_http_status(:ok)

      link = json_response.first
      expect(link['id']).to eq(issue2.id)
      expect(link['link_type']).to eq('blocks')
    end
  end

  describe 'POST #create' do
    def create_link(user, issue, target)
      sign_in(user)

      post_params = {
        namespace_id: issue.project.namespace.to_param,
        project_id: issue.project,
        issue_id: issue.iid,
        issuable_references: [target.to_reference],
        link_type: 'is_blocked_by'
      }

      post :create, params: post_params, as: :json
    end

    before do
      project.add_developer(user)
    end

    it 'returns success response' do
      create_link(user, issue1, issue2)

      expect(response).to have_gitlab_http_status(:ok)

      link = json_response['issuables'].first
      expect(link['id']).to eq(issue2.id)
      expect(link['link_type']).to eq('is_blocked_by')
    end

    context 'when blocked issues is disabled' do
      before do
        stub_licensed_features(blocked_issues: false)
      end

      it 'returns failure response' do
        create_link(user, issue1, issue2)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('Blocked issues not available for current license')
      end
    end
  end
end
