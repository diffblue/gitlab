# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupMembersController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, :public) }
  let(:membership) { create(:group_member, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'GET /groups/*group_id/-/group_members' do
    let(:banned_member) { create(:group_member, group: group) }
    let(:licensed_feature_available) { true }

    before do
      stub_licensed_features(unique_project_download_limit: licensed_feature_available)

      create(:namespace_ban, namespace: group, user: banned_member.user)
    end

    subject(:request) do
      get group_group_members_path(group_id: group)
    end

    it 'pushes feature flag to frontend' do
      request

      expect(response.body).to have_pushed_frontend_feature_flags(limitUniqueProjectDownloadsPerNamespaceUser: true)
    end

    it 'sets banned to include banned group members' do
      request

      expect(assigns(:banned).map(&:user_id)).to contain_exactly(banned_member.user.id)
    end

    shared_examples 'does not assign @banned' do
      it 'does not assign @banned' do
        request

        expect(assigns(:banned)).to be_nil
      end
    end

    context 'when licensed feature is not available' do
      let(:licensed_feature_available) { false }

      it_behaves_like 'does not assign @banned'
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(limit_unique_project_downloads_per_namespace_user: false)
      end

      it_behaves_like 'does not assign @banned'
    end

    context 'when sub-group' do
      before do
        group.update!(parent: create(:group))
      end

      it_behaves_like 'does not assign @banned'
    end

    context 'when user cannot manage members' do
      let(:another_group) { create(:group, :public) }

      subject(:request) do
        another_group.add_developer(user)

        get group_group_members_path(group_id: another_group)
      end

      it_behaves_like 'does not assign @banned'
    end
  end

  describe 'PUT /groups/*group_id/-/group_members/:id/unban' do
    let(:banned_member) { create(:group_member, group: group) }
    let!(:namespace_ban) { create(:namespace_ban, namespace: group, user: banned_member.user) }

    subject(:request) do
      put unban_group_group_member_path(group_id: group, id: banned_member)
    end

    it 'unbans the user' do
      expect_next_instance_of(::Users::Abuse::NamespaceBans::DestroyService, namespace_ban, user) do |service|
        expect(service).to receive(:execute)
      end

      subject
    end

    it 'redirects back to group members page' do
      subject

      expect(response).to redirect_to(group_group_members_path(group))
      expect(flash[:notice]).to eq "User was successfully unbanned."
    end
  end

  describe 'PUT /groups/*group_id/-/group_members/:id' do
    context 'when group has email domain feature enabled' do
      let(:email) { 'test@gitlab.com' }
      let(:member_user) { create(:user, email: email) }
      let!(:member) { group.add_guest(member_user) }

      before do
        stub_licensed_features(group_allowed_email_domains: true)
        create(:allowed_email_domain, group: group)
      end

      subject do
        put group_group_member_path(group_id: group, id: member), xhr: true, params: {
                                          group_member: {
                                            access_level: 50
                                          }
                                        }
      end

      context 'for a user with an email belonging to the allowed domain' do
        it 'returns error status' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'for a user with an un-verified email belonging to a domain different from the allowed domain' do
        let(:email) { 'test@gmail.com' }

        it 'returns error status' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          subject

          expect(json_response['message']).to eq("The member's email address is not allowed for this group. Check with your administrator.")
        end
      end
    end
  end
end
