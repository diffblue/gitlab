# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::V3::Github, feature_category: :integrations do
  describe 'GET /repos/:namespace/:project/pulls' do
    let_it_be(:private_group) { create(:group, :private) }
    let_it_be(:ip_restriction) { create(:ip_restriction, group: private_group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, creator: user, group: private_group) }

    let(:user_agent) { 'Jira DVCS Connector/3.2.4' }
    let(:path) { "/repos/#{project.namespace.path}/#{project.path}/pulls" }

    before do
      private_group.add_maintainer(user)
    end

    it_behaves_like 'a GitHub Enterprise Jira DVCS reversible end of life endpoint' do
      subject { get api(path, user, version: 'v3'), headers: { 'User-Agent' => user_agent } }
    end

    it 'returns status 200' do
      get api(path, user, version: 'v3'), headers: { 'User-Agent' => user_agent }

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'group_ip_restriction' do
      before do
        stub_licensed_features(group_ip_restriction: true)
      end

      it 'returns 404 for request from ip not in the range' do
        get api(path, user, version: 'v3'), headers: { 'User-Agent' => user_agent }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
