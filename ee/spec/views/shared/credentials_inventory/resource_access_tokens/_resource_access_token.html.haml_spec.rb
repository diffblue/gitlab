# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('shared/credentials_inventory/resource_access_tokens/_resource_access_token.html.haml') do
  let_it_be(:user) { create(:user) }

  context 'when access token is a project access token' do
    let_it_be(:project_bot) { create(:user, :project_bot, created_by_id: user.id) }
    let_it_be(:project_member) { create(:project_member, user: project_bot) }
    let_it_be(:project) { project_member.project }
    let_it_be(:project_access_token) do
      create(:personal_access_token, user: project_member.user, scopes: %w[read_repository api])
    end

    before do
      allow(view).to receive(:user_detail_path).and_return('abcd')

      render 'shared/credentials_inventory/resource_access_tokens/resource_access_token',
        resource_access_token: project_access_token
    end

    it 'shows the token name' do
      expect(rendered).to have_text(user.name)
    end

    it 'shows the token scopes' do
      expect(rendered).to have_text(project_access_token.scopes.join(', '))
    end

    it 'shows the link to the token project' do
      expect(rendered).to have_link(project.name, href: project_url(project))
    end

    it 'shows the token creator', :aggregate_failures do
      expect(rendered).to have_text(user.name)
      expect(rendered).to have_text(user.email)
    end

    it 'shows the created date' do
      expect(rendered).to have_text(project_access_token.created_at.to_date)
    end

    it 'shows the link to revoke the token' do
      expect(rendered).to have_link(
        'Revoke',
        href: admin_credential_resource_revoke_path(
          credential_id: project_access_token.id,
          resource_id: project.id,
          resource_type: 'Project'
        )
      )
    end

    context 'for last used date' do
      context 'when token has never been used' do
        let_it_be(:project_access_token) do
          create(:personal_access_token, user: project_member.user, scopes: %w[read_repository api], last_used_at: nil)
        end

        it 'displays Never' do
          expect(rendered).to have_text('Never')
        end
      end

      context 'when token has been used recently' do
        let_it_be(:project_access_token) do
          create(
            :personal_access_token,
            user: project_member.user,
            scopes: %w[read_repository api],
            last_used_at: DateTime.new(2001, 2, 3, 4, 5, 6)
          )
        end

        it 'displays the time last used' do
          expect(rendered).to have_text('2001-02-03')
        end
      end
    end

    context 'for expires date' do
      context 'when token has never been used' do
        let_it_be(:project_access_token) do
          create(:personal_access_token, user: project_member.user, scopes: %w[read_repository api], expires_at: nil)
        end

        it 'displays Never' do
          expect(rendered).to have_text('Never')
        end
      end

      context 'when token is set to expire' do
        let_it_be(:project_access_token) do
          create(
            :personal_access_token,
            user: project_member.user,
            scopes: %w[read_repository api],
            last_used_at: DateTime.new(2004, 2, 3, 4, 5, 6)
          )
        end

        it 'displays the expiration date' do
          expect(rendered).to have_text('2004-02-03')
        end
      end
    end
  end

  context 'when access token is a group access token' do
    let_it_be(:group_bot) { create(:user, :project_bot, created_by_id: user.id) }
    let_it_be(:group_member) { create(:group_member, user: group_bot) }
    let_it_be(:group) { group_member.group }
    let_it_be(:group_access_token) do
      create(:personal_access_token, user: group_member.user, scopes: %w[read_repository api])
    end

    before do
      allow(view).to receive(:user_detail_path).and_return('abcd')

      render 'shared/credentials_inventory/resource_access_tokens/resource_access_token',
        resource_access_token: group_access_token
    end

    it 'shows the token name' do
      expect(rendered).to have_text(user.name)
    end

    it 'shows the token scopes' do
      expect(rendered).to have_text(group_access_token.scopes.join(', '))
    end

    it 'shows the link to the token group' do
      expect(rendered).to have_link(group.name, href: group_url(group))
    end

    it 'shows the token creator', :aggregate_failures do
      expect(rendered).to have_text(user.name)
      expect(rendered).to have_text(user.email)
    end

    it 'shows the created date' do
      expect(rendered).to have_text(group_access_token.created_at.to_date)
    end

    it 'shows the link to revoke the token' do
      expect(rendered).to have_link(
        'Revoke',
        href: admin_credential_resource_revoke_path(
          credential_id: group_access_token.id,
          resource_id: group.id,
          resource_type: 'Group'
        )
      )
    end

    context 'for last used date' do
      context 'when token has never been used' do
        let_it_be(:group_access_token) do
          create(:personal_access_token, user: group_member.user, scopes: %w[read_repository api], last_used_at: nil)
        end

        it 'displays Never' do
          expect(rendered).to have_text('Never')
        end
      end

      context 'when token has been used recently' do
        let_it_be(:group_access_token) do
          create(
            :personal_access_token,
            user: group_member.user,
            scopes: %w[read_repository api],
            last_used_at: DateTime.new(2001, 2, 3, 4, 5, 6)
          )
        end

        it 'displays the time last used' do
          expect(rendered).to have_text('2001-02-03')
        end
      end
    end

    context 'for expires date' do
      context 'when token has never been used' do
        let_it_be(:group_access_token) do
          create(:personal_access_token, user: group_member.user, scopes: %w[read_repository api], expires_at: nil)
        end

        it 'displays Never' do
          expect(rendered).to have_text('Never')
        end
      end

      context 'when token is set to expire' do
        let_it_be(:group_access_token) do
          create(
            :personal_access_token,
            user: group_member.user,
            scopes: %w[read_repository api],
            last_used_at: DateTime.new(2004, 2, 3, 4, 5, 6))
        end

        it 'displays the expiration date' do
          expect(rendered).to have_text('2004-02-03')
        end
      end
    end
  end
end
