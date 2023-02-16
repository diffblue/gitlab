# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupMembersController, feature_category: :subgroups do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, :public) }
  let(:membership) { create(:group_member, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'GET /groups/*group_id/-/group_members' do
    let(:banned_member) { create(:group_member, :developer, group: group) }
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

    it 'sets @banned to include banned group members' do
      request

      expect(assigns(:banned).map(&:user_id)).to contain_exactly(banned_member.user.id)
    end

    it 'sets @members not to include banned group members' do
      request

      expect(assigns(:members).map(&:user_id)).not_to include(banned_member.user.id)
    end

    shared_examples 'assigns @banned and @members correctly' do
      it 'does not assign @banned' do
        request

        expect(assigns(:banned)).to be_nil
      end

      it 'sets @members to include banned group members' do
        request

        expect(assigns(:members).map(&:user_id)).to include(banned_member.user.id)
      end
    end

    context 'when licensed feature is not available' do
      let(:licensed_feature_available) { false }

      it_behaves_like 'assigns @banned and @members correctly'
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(limit_unique_project_downloads_per_namespace_user: false)
      end

      it_behaves_like 'assigns @banned and @members correctly'
    end

    context 'when sub-group' do
      before do
        group.update!(parent: create(:group))
      end

      it_behaves_like 'assigns @banned and @members correctly'
    end
  end

  describe 'PUT /groups/*group_id/-/group_members/:id/ban' do
    subject(:request) do
      put ban_group_group_member_path(group_id: group, id: member)
    end

    context 'when current user is an owner' do
      let(:member) { create(:group_member, :developer, group: group) }

      shared_examples 'bans the user' do
        it 'bans the user' do
          expected_args = { user: member.user, namespace: group }
          expect_next_instance_of(::Users::Abuse::NamespaceBans::CreateService, expected_args) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.success)
          end

          request
        end
      end

      it_behaves_like 'bans the user'

      it 'redirects back to group members page' do
        request

        expect(response).to redirect_to(group_group_members_path)
        expect(flash[:notice]).to eq "User was successfully banned."
      end

      context 'when ban fails' do
        let(:error_message) { 'Ban failed' }

        it 'redirects back to group members page with the error message as alert' do
          expected_args = { user: member.user, namespace: group }
          allow_next_instance_of(::Users::Abuse::NamespaceBans::CreateService, expected_args) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
          end

          request

          expect(response).to redirect_to(group_group_members_path(group))
          expect(flash[:alert]).to eq error_message
        end
      end
    end

    context 'when user cannot admin_group_member (not an owner)' do
      let(:another_group) { create(:group) }
      let(:member) { create(:group_member, group: another_group) }

      before do
        another_group.add_developer(user)
      end

      it 'returns 403' do
        put ban_group_group_member_path(group_id: another_group, id: member)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /groups/*group_id/-/group_members/:id/unban' do
    subject(:request) do
      put unban_group_group_member_path(group_id: group, id: banned_member)
    end

    context 'when current user is an owner' do
      let(:banned_member) { create(:group_member, :developer, group: group) }
      let!(:namespace_ban) { create(:namespace_ban, namespace: group, user: banned_member.user) }

      shared_examples 'unbans the user' do
        it 'unbans the user' do
          expect_next_instance_of(::Users::Abuse::NamespaceBans::DestroyService, namespace_ban, user) do |service|
            expect(service).to receive(:execute) { instance_double(ServiceResponse, "success?" => true) }
          end

          request
        end
      end

      it_behaves_like 'unbans the user'

      it 'redirects back to banned group members page' do
        request

        expect(response).to redirect_to(group_group_members_path(group, tab: 'banned'))
        expect(flash[:notice]).to eq "User was successfully unbanned."
      end

      context 'when unbanning a subgroup member' do
        let(:subgroup) { create(:group, parent: group) }
        let(:banned_member) { create(:group_member, group: subgroup) }
        let!(:namespace_ban) { create(:namespace_ban, namespace: group, user: banned_member.user) }

        it_behaves_like 'unbans the user'
      end

      context 'when member is not banned' do
        before do
          namespace_ban.destroy!
        end

        it 'returns 404' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when unban fails' do
        let(:error_message) { 'Unban failed' }

        it 'redirects back to banned group members page with the error message as alert' do
          allow_next_instance_of(::Users::Abuse::NamespaceBans::DestroyService, namespace_ban, user) do |service|
            service_result =  instance_double(ServiceResponse, "success?" => false, message: error_message)
            allow(service).to receive(:execute) { service_result }
          end

          request

          expect(response).to redirect_to(group_group_members_path(group, tab: 'banned'))
          expect(flash[:alert]).to eq error_message
        end
      end
    end

    context 'when user is not an owner' do
      let(:another_group) { create(:group) }
      let(:banned_member) { create(:group_member, group: another_group) }

      before do
        another_group.add_developer(user)
      end

      it 'returns 404' do
        put unban_group_group_member_path(group_id: another_group, id: banned_member)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
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

  describe "GET /groups/*group_id/-/group_members/export_csv" do
    before do
      stub_licensed_features(export_user_permissions: true)
    end

    subject do
      get export_csv_group_group_members_path(group)
    end

    it 'redirects back to members list' do
      subject
      expect(response).to redirect_to(group_group_members_path(group))
    end

    context 'when LDAP sync is enabled' do
      before do
        allow_next_found_instance_of(Group) do |instance|
          allow(instance).to receive(:ldap_synced?).and_return(true)
        end
      end

      it 'redirects back to members list' do
        subject
        expect(response).to redirect_to(group_group_members_path(group))
      end
    end
  end
end
