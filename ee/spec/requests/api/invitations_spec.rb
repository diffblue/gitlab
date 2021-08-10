# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Invitations, 'EE Invitations' do
  include GroupAPIHelpers

  let_it_be(:admin) { create(:user, :admin, email: 'admin@example.com') }
  let_it_be(:group) { create(:group) }

  let(:url) { "/groups/#{group.id}/invitations" }
  let(:invite_email) { 'restricted@example.org' }

  shared_examples 'restricted email error' do |message, code|
    it 'returns an http error response and the validation message' do
      post api(url, admin),
      params: { email: invite_email, access_level: Member::MAINTAINER }

      expect(response).to have_gitlab_http_status(code)
      expect(json_response['message'][invite_email]).to eq message
    end
  end

  shared_examples 'admin signup restrictions email error' do
    context 'when restricted by admin signup restriction - denylist' do
      before do
        stub_application_setting(domain_denylist_enabled: true)
        stub_application_setting(domain_denylist: ['example.org'])
      end

      # this response code should be changed to 4xx: https://gitlab.com/gitlab-org/gitlab/-/issues/321706
      it_behaves_like 'restricted email error', 'User is not from an allowed domain.', :created
    end

    context 'when restricted by admin signup restriction - allowlist' do
      before do
        stub_application_setting(domain_allowlist: ['example.com'])
      end

      # this response code should be changed to 4xx: https://gitlab.com/gitlab-org/gitlab/-/issues/321706
      it_behaves_like 'restricted email error', 'User domain is not authorized for sign-up.', :created
    end

    context 'when restricted by admin signup restriction - email restrictions' do
      before do
        stub_application_setting(email_restrictions_enabled: true)
        stub_application_setting(email_restrictions: '([\+]|\b(\w*example.org\w*)\b)')
      end

      # this response code should be changed to 4xx: https://gitlab.com/gitlab-org/gitlab/-/issues/321706
      it_behaves_like 'restricted email error', 'User is not allowed. Try again with a different email address, or contact your GitLab admin.', :created
    end
  end

  describe 'POST /groups/:id/invitations' do
    context 'when the group is restricted by admin signup restrictions' do
      it_behaves_like 'admin signup restrictions email error'
    end

    context 'when the group is restricted by group signup restriction - allowed domains for signup' do
      before do
        stub_licensed_features(group_allowed_email_domains: true)
        create(:allowed_email_domain, group: group, domain: 'example.com')
      end

      # this response code should be changed to 4xx: https://gitlab.com/gitlab-org/gitlab/-/issues/321706
      it_behaves_like 'restricted email error', "Invite email email does not match the allowed domain of example.com", :success
    end
  end

  describe 'POST /projects/:id/invitations' do
    let_it_be(:project) { create(:project, namespace: group) }

    let(:url) { "/projects/#{project.id}/invitations" }

    context 'when the project is restricted by admin signup restrictions' do
      it_behaves_like 'admin signup restrictions email error'
    end
  end
end
