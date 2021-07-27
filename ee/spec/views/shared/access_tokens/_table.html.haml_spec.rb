# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/access_tokens/_table.html.haml' do
  let(:type) { 'token' }
  let(:type_plural) { 'tokens' }
  let(:token_expiry_enforced?) { false }
  let(:impersonation) { false }

  let_it_be(:user) { create(:user) }
  let_it_be(:tokens) { [create(:personal_access_token, user: user)] }
  let_it_be(:project) { false }

  before do
    stub_licensed_features(enforce_personal_access_token_expiration: true)
    allow(Gitlab::CurrentSettings).to receive(:enforce_pat_expiration?).and_return(false)

    allow(view).to receive(:personal_access_token_expiration_enforced?).and_return(token_expiry_enforced?)
    allow(view).to receive(:show_profile_token_expiry_notification?).and_return(true)
    allow(view).to receive(:distance_of_time_in_words_to_now).and_return('4 days')

    if project
      project.add_maintainer(user)
    end

    locals = {
      type: type,
      type_plural: type_plural,
      active_tokens: tokens,
      project: project,
      impersonation: impersonation,
      revoke_route_helper: ->(token) { 'path/' }
    }

    render partial: 'shared/access_tokens/table', locals: locals
  end

  shared_examples 'does not show the token expiry notification' do
    it do
      expect(rendered).not_to have_content 'tokens have expired'
    end
  end

  context 'if impersonation' do
    let(:impersonation) { true }

    it_behaves_like 'does not show the token expiry notification'
  end

  context 'if project' do
    let_it_be(:project) { create(:project) }

    it_behaves_like 'does not show the token expiry notification'
  end

  context 'without tokens' do
    let_it_be(:tokens) { [] }

    it_behaves_like 'does not show the token expiry notification'
  end

  context 'with tokens' do
    let_it_be(:tokens) do
      [
        create(:personal_access_token, user: user, name: 'Access token', last_used_at: 1.day.ago, expires_at: nil),
        create(:personal_access_token, user: user, expires_at: 5.days.ago),
        create(:personal_access_token, user: user, expires_at: Time.now),
        create(:personal_access_token, user: user, expires_at: 5.days.from_now, scopes: [:read_api, :read_user])
      ]
    end

    it 'shows the token expiry notification', :aggregate_failures do
      expect(rendered).to render_template('profiles/personal_access_tokens/_token_expiry_notification', active_tokens: tokens)
      expect(rendered).to have_content '2 tokens have expired'
    end
  end
end
