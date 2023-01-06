# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::Users", :js, feature_category: :user_management do
  let_it_be(:user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user)
  end

  describe 'GET /admin/users' do
    describe 'send emails to users' do
      context 'when `send_emails_from_admin_area` feature is enabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: true)
        end

        it "shows the 'Send email to users' link" do
          visit admin_users_path

          expect(page).to have_link(href: admin_email_path)
        end
      end

      context 'when `send_emails_from_admin_area` feature is disabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: false)
          stub_application_setting(usage_ping_enabled: false)
        end

        it "does not show the 'Send email to users' link" do
          visit admin_users_path

          expect(page).not_to have_link(href: admin_email_path)
        end
      end

      context 'when usage ping is enabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: false)
          stub_application_setting(usage_ping_enabled: true)
        end

        context 'when feature is activated' do
          before do
            stub_application_setting(usage_ping_features_enabled: true)
          end

          it "shows the 'Send email to users' link" do
            visit admin_users_path

            expect(page).to have_link(href: admin_email_path)
          end
        end

        context 'when feature is disabled' do
          before do
            stub_application_setting(usage_ping_features_enabled: false)
          end

          it "does not show the 'Send email to users' link" do
            visit admin_users_path

            expect(page).not_to have_link(href: admin_email_path)
          end
        end
      end
    end

    describe 'user permission export' do
      context 'when `export_user_permissions` feature is available' do
        before do
          stub_licensed_features(export_user_permissions: true)
        end

        it "shows the 'Export Permissions' link" do
          visit admin_users_path

          expect(page).to have_link(href: admin_user_permission_exports_path(format: :csv))
        end
      end

      context 'when `export_user_permissions` feature is disabled' do
        before do
          stub_licensed_features(export_user_permissions: false)
        end

        it "does not show the 'Export Permissions' link" do
          visit admin_users_path

          expect(page).not_to have_link(href: admin_user_permission_exports_path(format: :csv))
        end
      end
    end
  end

  describe "GET /admin/users/:id" do
    describe 'Shared runners quota status' do
      before do
        user.namespace.update!(shared_runners_minutes_limit: 500)
      end

      context 'with projects with shared runners enabled' do
        before do
          create(:project, namespace: user.namespace, shared_runners_enabled: true)
        end

        it 'shows quota' do
          visit admin_users_path

          click_link user.name

          expect(page).to have_content('Quota of CI/CD minutes: 0 / 500')
        end
      end

      context 'without projects with shared runners enabled' do
        before do
          create(:project, namespace: user.namespace, shared_runners_enabled: false)
        end

        it 'does not show quota' do
          visit admin_users_path

          click_link user.name

          expect(page).not_to have_content('Quota of CI/CD minutes:')
        end
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    describe "Update user account type" do
      before do
        visit_edit_user(user.id)

        allow_next_instance_of(AuditorUserHelper) do |instance|
          allow(instance).to receive(:license_allows_auditor_user?).and_return(true)
        end
        choose "user_access_level_auditor"
        click_button "Save changes"
      end

      it "changes account type to be auditor" do
        user.reload

        expect(user).not_to be_admin
        expect(user).to be_auditor
      end
    end

    describe 'Update shared runners quota' do
      let_it_be(:project) { create(:project, namespace: user.namespace, shared_runners_enabled: true) }

      it "shows page with new data" do
        visit_edit_user(user.id)
        fill_in "user_namespace_attributes_shared_runners_minutes_limit", with: "500"

        click_button "Save changes"

        expect(page).to have_content('Quota of CI/CD minutes: 0 / 500')
      end
    end

    def visit_edit_user(user_id)
      visit admin_users_path

      page.within("[data-testid='user-actions-#{user_id}']") do
        click_link 'Edit'
      end
    end
  end

  describe 'show user keys for SSH and LDAP' do
    let_it_be(:key1) do
      create(:ldap_key, user: user, title: "LDAP Key1")
    end

    let_it_be(:key2) do
      create(:key, user: user, title: "ssh-rsa Key2")
    end

    it 'only shows the delete button for regular keys' do
      visit admin_users_path

      click_link user.name
      click_link 'SSH keys'

      # Check that the regular Key shows the delete icon and the LDAPKey does not

      # SSH key should be the first in the list
      within('ul.content-list li.key-list-item:nth-of-type(1)') do
        expect(page).to have_content(key2.title)
        expect(page).to have_content('Remove')
        expect(page).not_to have_content('Revoke')
      end

      # Next, LDAP key
      within('ul.content-list li.key-list-item:nth-of-type(2)') do
        expect(page).to have_content(key1.title)
        expect(page).not_to have_content('Remove')
        expect(page).not_to have_content('Revoke')
      end
    end
  end

  describe 'prompt user about registration features' do
    let(:message) { s_("RegistrationFeatures|Want to %{feature_title} for free?") % { feature_title: s_('RegistrationFeatures|send emails to users') } }

    context 'with no license and service ping disabled' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(usage_ping_enabled: false)
      end

      it 'renders registration features CTA' do
        visit admin_users_path

        expect(page).to have_content(message)
        expect(page).to have_link(s_('RegistrationFeatures|Registration Features Program'))
        expect(page).to have_link(s_('RegistrationFeatures|Enable Service Ping and register for this feature.'))
      end
    end

    context 'with a valid license and service ping disabled' do
      before do
        license = build(:license)
        allow(License).to receive(:current).and_return(license)
        stub_application_setting(usage_ping_enabled: false)
      end

      it 'does not render registration features CTA' do
        visit admin_users_path

        expect(page).not_to have_content(message)
      end
    end
  end
end
