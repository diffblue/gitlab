# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Invitations, 'EE Invitations', :aggregate_failures, feature_category: :user_profile do
  include GroupAPIHelpers

  let_it_be(:admin) { create(:user, :admin, email: 'admin@example.com') }
  let_it_be(:group, reload: true) { create(:group) }

  let(:url) { "/groups/#{group.id}/invitations" }
  let(:invite_email) { 'restricted@example.org' }

  shared_examples 'restricted email error' do |message, code|
    it 'returns an http error response and the validation message' do
      post api(url, admin, admin_mode: true),
      params: { email: invite_email, access_level: Member::MAINTAINER }

      expect(response).to have_gitlab_http_status(code)
      expect(json_response['message'][invite_email]).to eq message
    end
  end

  shared_examples 'admin signup restrictions email error - denylist' do |message, code|
    before do
      stub_application_setting(domain_denylist_enabled: true)
      stub_application_setting(domain_denylist: ['example.org'])
    end

    it_behaves_like 'restricted email error', message, code
  end

  shared_examples 'admin signup restrictions email error - allowlist' do |message, code|
    before do
      stub_application_setting(domain_allowlist: ['example.com'])
    end

    it_behaves_like 'restricted email error', message, code
  end

  shared_examples 'admin signup restrictions email error - email restrictions' do |message, code|
    before do
      stub_application_setting(email_restrictions_enabled: true)
      stub_application_setting(email_restrictions: '([\+]|\b(\w*example.org\w*)\b)')
    end

    it_behaves_like 'restricted email error', message, code
  end

  shared_examples 'member creation audit event' do
    it 'creates an audit event while creating a new member' do
      params = { email: 'example1@example.com', access_level: Member::DEVELOPER }

      expect do
        post api(url, admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:created)
      end.to change { AuditEvent.count }.by(1)
    end

    it 'does not create audit event if creating a new member fails' do
      params = { email: '_bogus_', access_level: Member::DEVELOPER }

      expect do
        post api(url, admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end.not_to change { AuditEvent.count }
    end
  end

  describe 'POST /groups/:id/invitations' do
    it_behaves_like 'member creation audit event'
    it_behaves_like 'admin signup restrictions email error - denylist', "The member's email address is not allowed for this group. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check the &#39;Domain denylist&#39;.", :created

    it_behaves_like 'POST request permissions for admin mode' do
      let(:path) { url }
      let(:params) { { email: 'example1@example.com', access_level: Member::DEVELOPER } }
    end

    context 'when the group is restricted by admin signup restrictions' do
      it_behaves_like 'admin signup restrictions email error - allowlist', "The member's email address is not allowed for this group. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Allowed domains for sign-ups&#39;.", :created
      it_behaves_like 'admin signup restrictions email error - email restrictions', "The member's email address is not allowed for this group. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Email restrictions for sign-ups&#39;.", :created
    end

    context 'when the group is restricted by group signup restriction - allowed domains for signup' do
      before do
        stub_licensed_features(group_allowed_email_domains: true)
        create(:allowed_email_domain, group: group, domain: 'example.com')
      end

      it_behaves_like 'restricted email error', "The member's email address is not allowed for this group. Go to the group’s &#39;Settings &gt; General&#39; page, and check &#39;Restrict membership by email domain&#39;.", :success
    end

    context 'with free user cap considerations', :saas do
      let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }

      before do
        stub_ee_application_setting(dashboard_limit_enabled: true)
      end

      subject(:post_invitations) do
        post api(url, admin, admin_mode: true),
             params: { email: invite_email, access_level: Member::MAINTAINER }
      end

      shared_examples 'does not add members' do
        it 'does not add the member' do
          expect do
            post_invitations
          end.not_to change { group.members.count }

          msg = "cannot be added since you've reached your #{::Namespaces::FreeUserCap.dashboard_limit} " \
                "member limit for #{group.name}"
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['status']).to eq('error')
          expect(json_response['message'][invite_email]).to eq(msg)
        end
      end

      context 'when there are at the size limit' do
        it_behaves_like 'does not add members'
      end

      context 'when there are over the size limit' do
        before do
          stub_ee_application_setting(dashboard_enforcement_limit: 3) # allow us to add a user/member
          group.add_developer(create(:user))
          stub_ee_application_setting(dashboard_enforcement_limit: 0) # set us up to now be over
        end

        it_behaves_like 'does not add members'
      end

      context 'when there is a seat left' do
        before do
          stub_ee_application_setting(dashboard_enforcement_limit: 3)
        end

        it 'creates a member' do
          expect { post_invitations }.to change { group.members.count }.by(1)
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['status']).to eq('success')
        end
      end

      context 'when there are seats left and we add enough to exhaust all seats' do
        before do
          stub_ee_application_setting(dashboard_enforcement_limit: 1)
        end

        it 'creates one member and errors on the other member' do
          expect do
            stranger = create(:user)
            stranger2 = create(:user)
            user_id_list = "#{stranger.id},#{stranger2.id}"

            post api(url, admin, admin_mode: true), params: { user_id: user_id_list, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['status']).to eq('error')
            expect(json_response['message'][stranger2.username]).to match(/cannot be added since you've reached your/)
          end.to change { group.members.count }.by(1)
        end
      end
    end

    context 'with minimal access level' do
      before do
        stub_licensed_features(minimal_access_role: true)
      end

      context 'when group has no parent' do
        it 'return success' do
          post api(url, admin, admin_mode: true),
               params: { email: invite_email,
                         access_level: Member::MINIMAL_ACCESS }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['status']).to eq("success")
        end
      end

      context 'when group has parent' do
        let(:parent_group) { create(:group) }
        let(:group) { create(:group, parent: parent_group) }

        it 'return error' do
          post api(url, admin, admin_mode: true),
               params: { email: invite_email,
                         access_level: Member::MINIMAL_ACCESS }

          expect(json_response['status']).to eq 'error'
          expect(json_response['message'][invite_email]).to include('Access level is not included in the list')
        end
      end
    end
  end

  describe 'POST /projects/:id/invitations' do
    let_it_be(:project) { create(:project, namespace: group) }

    let(:url) { "/projects/#{project.id}/invitations" }

    it_behaves_like 'member creation audit event'

    it_behaves_like 'POST request permissions for admin mode' do
      let(:path) { url }
      let(:params) { { email: 'example1@example.com', access_level: Member::DEVELOPER } }
      let(:failed_status_code) { :not_found }
    end

    context 'with group membership locked' do
      before do
        group.update!(membership_lock: true)
      end

      it 'returns an error and exception message when group membership lock is enabled' do
        params = { email: 'example1@example.com', access_level: Member::DEVELOPER }

        post api(url, admin, admin_mode: true), params: params

        expect(json_response['message']).to eq 'Members::CreateService::MembershipLockedError'
        expect(json_response['status']).to eq 'error'
      end
    end

    context 'when the project is restricted by admin signup restrictions' do
      it_behaves_like 'admin signup restrictions email error - denylist', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check the &#39;Domain denylist&#39;.", :created
      context 'when the group is restricted by admin signup restrictions' do
        it_behaves_like 'admin signup restrictions email error - allowlist', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Allowed domains for sign-ups&#39;.", :created
        it_behaves_like 'admin signup restrictions email error - email restrictions', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Email restrictions for sign-ups&#39;.", :created
      end
    end
  end

  context 'group with LDAP group link' do
    include LdapHelpers

    let(:group) { create(:group_with_ldap_group_link, :public) }
    let(:owner) { create(:user) }
    let(:developer) { create(:user) }
    let(:invite) { create(:group_member, :invited, source: group, user: developer) }

    before do
      create(:group_member, :owner, group: group, user: owner)
      stub_ldap_setting(enabled: true)
      stub_application_setting(lock_memberships_to_ldap: true)
    end

    describe 'POST /groups/:id/invitations' do
      it 'returns a forbidden response' do
        post api("/groups/#{group.id}/invitations", owner), params: { email: developer.email, access_level: Member::DEVELOPER }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'PUT /groups/:id/invitations/:email' do
      it 'returns a forbidden response' do
        put api("/groups/#{group.id}/invitations/#{invite.invite_email}", owner), params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'DELETE /groups/:id/invitations/:email' do
      it 'returns a forbidden response' do
        delete api("/groups/#{group.id}/invitations/#{invite.invite_email}", owner)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
