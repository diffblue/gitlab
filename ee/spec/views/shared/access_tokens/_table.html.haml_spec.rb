# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/access_tokens/_table.html.haml' do
  let(:type) { 'token' }
  let(:type_plural) { 'tokens' }
  let(:impersonation) { false }

  let_it_be(:user) { create(:user) }
  let_it_be(:tokens) { [create(:personal_access_token, user: user)] }
  let_it_be(:project) { false }

  before do
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

  context 'with tokens' do
    let_it_be(:tokens) do
      [
        create(:personal_access_token, user: user, name: 'Peanuts', last_used_at: 1.day.ago, expires_at: nil),
        create(:personal_access_token, user: user, name: 'Marmite', expires_at: 5.days.from_now, scopes: [:read_api, :read_user])
      ]
    end

    it 'shows the token expiry notification', :aggregate_failures do
      expect(rendered).to have_content 'Peanuts'
      expect(rendered).to have_content 'Marmite'
    end
  end
end
