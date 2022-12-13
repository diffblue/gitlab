# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProtectedTags, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_projects: [project]) }

  let(:invited_group) { create(:project_group_link, project: project).group }
  let(:project_member) { create(:project_member, project: project).user }
  let(:protected_name) { 'feature' }
  let(:tag_name) { protected_name }

  let!(:protected_tag) do
    create(:protected_tag, project: project, name: protected_name)
  end

  describe "GET /projects/:id/protected_tags" do
    let(:route) { "/projects/#{project.id}/protected_tags" }

    it 'returns user and group ids for the access levels' do
      protected_tag.create_access_levels.create!(user: project_member)

      get api(route, user)

      expect(response).to have_gitlab_http_status(:ok)

      user_ids = json_response.last['create_access_levels'].map { |level| level['user_id'] }
      expect(user_ids).to match_array([nil, project_member.id])
    end
  end

  describe "GET /projects/:id/protected_tags/:tag" do
    let(:route) { "/projects/#{project.id}/protected_tags/#{tag_name}" }

    it 'returns user and group ids for the access levels' do
      protected_tag.create_access_levels.create!(group: invited_group)

      get api(route, user)

      group_ids = json_response['create_access_levels'].map { |level| level['group_id'] }
      expect(group_ids).to match_array([nil, invited_group.id])
    end
  end

  describe 'POST /projects/:id/protected_tags' do
    let(:tag_name) { 'new_tag' }
    let(:post_endpoint) { api("/projects/#{project.id}/protected_tags", user) }

    def expect_protection_to_be_successful
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(tag_name)
    end

    context 'with granular access' do
      it 'can protect a tag while allowing an individual user to create tags' do
        post post_endpoint, params: { name: tag_name, allowed_to_create: [{ user_id: project_member.id }] }

        expect_protection_to_be_successful
        expect(json_response['create_access_levels'][0]['user_id']).to eq(project_member.id)
      end

      it 'can protect a tag while allowing a group to create tags' do
        post post_endpoint, params: { name: tag_name, allowed_to_create: [{ group_id: invited_group.id }] }

        expect_protection_to_be_successful
        expect(json_response['create_access_levels'][0]['group_id']).to eq(invited_group.id)
      end

      it 'avoids creating default access levels unless necessary' do
        post post_endpoint, params: { name: tag_name, allowed_to_create: [{ user_id: project_member.id }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['create_access_levels'].count).to eq(1)
        expect(json_response['create_access_levels'][0]['user_id']).to eq(project_member.id)
        expect(json_response['create_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      context 'when protected_refs_for_users feature is not available' do
        before do
          stub_licensed_features(protected_refs_for_users: false)
        end

        it 'cannot protect a tag for a user or group only' do
          allowed_to_create_param = [{ group_id: invited_group.id, user_id: project_member.id }]
          post post_endpoint, params: { name: tag_name, allowed_to_create: allowed_to_create_param }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
