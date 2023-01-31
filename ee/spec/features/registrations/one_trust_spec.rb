# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OneTrust in the sign up flow', feature_category: :system_access do
  let_it_be(:onetrust_url) { 'https://*.onetrust.com' }
  let_it_be(:one_trust_id) { SecureRandom.uuid }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    stub_config(extra: { one_trust_id: one_trust_id })
    stub_feature_flags(ecomm_instrumentation: true)
    allow(::Gitlab).to receive(:com?).and_return(true)
    sign_in(user)
  end

  shared_examples_for 'one trust settings' do
    it 'has the OneTrust CSP settings', :aggregate_failures do
      expect(response_headers['Content-Security-Policy']).to include(onetrust_url)
      expect(page.html).to include("https://cdn.cookielaw.org/consent/#{one_trust_id}/OtAutoBlock.js")
    end
  end

  context 'when user visits /users/sign_up/groups_projects/new' do
    before do
      visit new_users_sign_up_groups_project_path
    end

    it_behaves_like 'one trust settings'
  end
end
