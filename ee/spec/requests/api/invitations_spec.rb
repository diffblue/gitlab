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

  describe 'POST /groups/:id/invitations' do
    it_behaves_like 'admin signup restrictions email error - denylist', "The member's email address is not allowed for this group. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check the &#39;Domain denylist&#39;.", :created
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
  end

  describe 'POST /projects/:id/invitations' do
    let_it_be(:project) { create(:project, namespace: group) }

    let(:url) { "/projects/#{project.id}/invitations" }

    context 'when the project is restricted by admin signup restrictions' do
      it_behaves_like 'admin signup restrictions email error - denylist', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check the &#39;Domain denylist&#39;.", :created
      context 'when the group is restricted by admin signup restrictions' do
        it_behaves_like 'admin signup restrictions email error - allowlist', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Allowed domains for sign-ups&#39;.", :created
        it_behaves_like 'admin signup restrictions email error - email restrictions', "The member's email address is not allowed for this project. Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check &#39;Email restrictions for sign-ups&#39;.", :created
      end
    end
  end
end
