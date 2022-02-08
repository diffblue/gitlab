# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('shared/credentials_inventory/personal_access_tokens/_project_access_token.html.haml') do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_bot) { create(:user, :project_bot, created_by_id: user.id) }
  let_it_be(:project_member) { create(:project_member, user: project_bot) }
  let_it_be(:project_access_token) { create(:personal_access_token, user: project_member.user, scopes: %w(read_repository api)) }

  before do
    allow(view).to receive(:user_detail_path).and_return('abcd')

    render 'shared/credentials_inventory/project_access_tokens/project_access_token', project_access_token: project_access_token
  end

  it 'shows the token name' do
    expect(rendered).to have_text(user.name)
  end

  it 'shows the token scopes' do
    expect(rendered).to have_text(project_access_token.scopes.join(', '))
  end

  it 'shows the token project' do
    expect(rendered).to have_text(project_member.project.name)
  end

  it 'shows the token creator', :aggregate_failures do
    expect(rendered).to have_text(user.name)
    expect(rendered).to have_text(user.email)
  end

  it 'shows the created date' do
    expect(rendered).to have_text(project_access_token.created_at.to_s)
  end

  context 'last used date' do
    context 'when token has never been used' do
      let_it_be(:project_access_token) { create(:personal_access_token, user: project_member.user, scopes: %w(read_repository api), last_used_at: nil) }

      it 'displays Never' do
        expect(rendered).to have_text('Never')
      end
    end

    context 'when token has been used recently' do
      let_it_be(:project_access_token) { create(:personal_access_token, user: project_member.user, scopes: %w(read_repository api), last_used_at: DateTime.new(2001, 2, 3, 4, 5, 6)) }

      it 'displays the time last used' do
        expect(rendered).to have_text('2001-02-03 04:05:06 UTC')
      end
    end
  end

  context 'expires date' do
    context 'when token has never been used' do
      let_it_be(:project_access_token) { create(:personal_access_token, user: project_member.user, scopes: %w(read_repository api), expires_at: nil) }

      it 'displays Never' do
        expect(rendered).to have_text('Never')
      end
    end

    context 'when token is set to expire' do
      let_it_be(:project_access_token) { create(:personal_access_token, user: project_member.user, scopes: %w(read_repository api), last_used_at: DateTime.new(2004, 2, 3, 4, 5, 6)) }

      it 'displays the expiration date' do
        expect(rendered).to have_text('2004-02-03 04:05:06 UTC')
      end
    end
  end
end
