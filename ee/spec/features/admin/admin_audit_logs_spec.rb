# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::AuditLogs', :js, feature_category: :audit_events do
  include AdminModeHelper

  let(:user) { create(:user) }
  let(:admin) { create(:admin, name: 'Bruce Wayne') }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(admin_audit_log: false)
    end

    it 'returns 404' do
      reqs = inspect_requests do
        visit admin_audit_logs_path
      end

      expect(reqs.first.status_code).to eq(404)
    end
  end

  context 'licensed' do
    before do
      stub_licensed_features(admin_audit_log: true)
    end

    it 'has Audit Events button in head nav bar' do
      visit admin_audit_logs_path

      expect(page).to have_link('Audit Events', href: admin_audit_logs_path)
    end

    describe 'release created events' do
      let(:project) { create(:project) }
      let(:release) { create(:release, project: project, tag: 'v0.1', author: user) }

      before do
        AuditEvents::ReleaseCreatedAuditEventService.new(user, project, '127.0.0.1', release).security_event
      end

      it 'shows the related audit event' do
        visit admin_audit_logs_path

        expect(page).to have_content('Created Release')
      end
    end

    describe 'user events' do
      before do
        AuditEventService.new(user, user, with: :ldap)
          .for_authentication.security_event

        visit admin_audit_logs_path
      end

      it 'filters by user' do
        filter_for('User Events', user.name)

        expect(page).to have_content('Signed in with LDAP authentication')
      end
    end

    describe 'group events' do
      let(:group_member) { create(:group_member, user: user) }

      before do
        AuditEventService.new(user, group_member.group, { action: :create })
          .for_member(group_member).security_event

        visit admin_audit_logs_path
      end

      it 'filters by group' do
        filter_for('Group Events', group_member.group.name)

        expect(page).to have_content('Added user access as Owner')
      end
    end

    describe 'project events' do
      let(:project_member) { create(:project_member, user: user) }
      let(:project) { project_member.project }

      before do
        AuditEventService.new(user, project, { action: :destroy })
          .for_member(project_member).security_event

        visit admin_audit_logs_path
      end

      it 'filters by project' do
        filter_for('Project Events', project_member.project.name)

        expect(page).to have_content('Removed user access')
      end
    end

    describe 'filter by date' do
      let_it_be(:audit_event_1) { create(:user_audit_event, created_at: 5.days.ago) }
      let_it_be(:audit_event_2) { create(:user_audit_event, created_at: 3.days.ago) }
      let_it_be(:audit_event_3) { create(:user_audit_event, created_at: Date.current) }
      let_it_be(:events_path) { :admin_audit_logs_path }
      let_it_be(:entity) { nil }

      it_behaves_like 'audit events date filter'
    end

    describe 'personal access token events' do
      shared_examples 'personal access token audit event' do
        it 'show personal access token event details' do
          visit admin_audit_logs_path

          expect(page).to have_content(message)
        end
      end

      context 'create personal access token' do
        let(:personal_access_token_params) { { name: 'Test token', impersonation: false, scopes: [:api], expires_at: Date.today + 1.month } }
        let(:personal_access_token) do
          PersonalAccessTokens::CreateService.new(
            current_user: admin, target_user: user, params: personal_access_token_params
          ).execute.payload[:personal_access_token]
        end

        context 'when creation succeeds' do
          before do
            enable_admin_mode!(admin)
            personal_access_token
          end

          let(:message) { "Created personal access token with id #{personal_access_token.id}" }

          it_behaves_like 'personal access token audit event'
        end

        context 'when creation fails' do
          before do
            allow_next_instance_of(ServiceResponse) do |instance|
              allow(instance).to receive(:success?).and_return(false)
              allow(instance).to receive(:message).and_return('error')
            end
            personal_access_token
          end

          let(:message) { "Attempted to create personal access token but failed with message: error" }

          it_behaves_like 'personal access token audit event'
        end
      end

      context 'revoke personal access token' do
        let(:personal_access_token) { create(:personal_access_token, user: user) }

        context 'when revocation succeeds' do
          before do
            enable_admin_mode!(admin)
            PersonalAccessTokens::RevokeService.new(admin, token: personal_access_token).execute
          end

          let(:message) { "Revoked personal access token with id #{personal_access_token.id}" }

          it_behaves_like 'personal access token audit event'
        end

        context 'when revocation fails' do
          let(:message) { "Attempted to revoke personal access token with id #{personal_access_token.id} but failed with message: error" }

          before do
            allow_next_instance_of(ServiceResponse) do |instance|
              allow(instance).to receive(:success?).and_return(false)
              allow(instance).to receive(:message).and_return('error')
            end
            PersonalAccessTokens::RevokeService.new(admin, token: personal_access_token).execute
          end

          it_behaves_like 'personal access token audit event'
        end
      end
    end

    describe 'impersonated events' do
      it 'show impersonation details' do
        visit admin_user_path(user)

        click_link 'Impersonate'

        visit(new_project_path)
        click_link 'Create blank project'

        fill_in(:project_name, with: 'Gotham City')

        page.within('#content-body') do
          click_button('Create project')
        end

        visit(new_project_path)
        click_link 'Stop impersonation'

        visit admin_audit_logs_path

        expect(page).to have_content('by Bruce Wayne')
      end
    end
  end

  def filter_for(type, name)
    filter_container = '[data-testid="audit-events-filter"]'

    find(filter_container).click
    within filter_container do
      click_link type
      click_link name

      find('button[type="button"]:not([name="clear"]):not([aria-label="Close"]').click
    end

    wait_for_requests
  end
end
