# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit group settings' do
  include Select2Helper

  let_it_be(:user) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group, name: 'Foo bar', path: 'foo') }

  before_all do
    group.add_owner(user)
    group.add_developer(developer)
  end

  before do
    sign_in(user)
  end

  describe 'navbar' do
    context 'with LDAP enabled' do
      before do
        allow_any_instance_of(EE::Group).to receive(:ldap_synced?).and_return(true)
        allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
      end

      it 'is able to navigate to LDAP group section' do
        visit edit_group_path(group)

        expect(find('.nav-sidebar')).to have_content('LDAP Synchronization')
      end

      context 'with owners not being able to manage LDAP' do
        it 'is not able to navigate to LDAP group section' do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)

          visit edit_group_path(group)

          expect(find('.nav-sidebar')).not_to have_content('LDAP Synchronization')
        end
      end
    end
  end

  context 'with webhook feature enabled' do
    it 'shows the menu item' do
      stub_licensed_features(group_webhooks: true)

      visit edit_group_path(group)

      within('.nav-sidebar') do
        expect(page).to have_link('Webhooks')
      end
    end
  end

  context 'with webhook feature disabled' do
    it 'does not show the menu item' do
      stub_licensed_features(group_webhooks: false)

      visit edit_group_path(group)

      within('.nav-sidebar') do
        expect(page).not_to have_link('Webhooks')
      end
    end
  end

  describe 'Member Lock setting' do
    context 'without a license key' do
      before do
        License.delete_all
      end

      it 'is not visible' do
        visit edit_group_path(group)

        expect(page).not_to have_content('Member lock')
      end
    end

    context 'with a license key' do
      it 'is visible' do
        visit edit_group_path(group)

        expect(page).to have_content('Member lock')
      end

      context 'when current user is not the Owner' do
        before do
          sign_in(developer)
        end

        it 'is not visible' do
          visit edit_group_path(group)

          expect(page).not_to have_content('Member lock')
        end
      end
    end
  end

  describe 'Group file templates setting' do
    context 'without a license key' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: false)
      end

      it 'is not visible' do
        visit edit_group_path(group)

        expect(page).not_to have_content('Select a template repository')
      end
    end

    context 'with a license key' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'is visible' do
        visit edit_group_path(group)

        expect(page).to have_content('Select a template repository')
      end

      it 'allows a project to be selected', :js do
        project = create(:project, namespace: group, name: 'known project')

        visit edit_group_path(group)

        page.within('section#js-templates') do |page|
          select2(project.id, from: '#group_file_template_project_id')
          click_button 'Save changes'
          wait_for_requests

          expect(group.reload.checked_file_template_project).to eq(project)
        end
      end

      context 'when current user is not the Owner' do
        before do
          sign_in(developer)
        end

        it 'is not visible' do
          visit edit_group_path(group)

          expect(page).not_to have_content('Select a template repository')
        end
      end
    end
  end

  context 'enable delayed project removal' do
    before do
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
    end

    it_behaves_like 'a cascading setting' do
      let_it_be(:subgroup) { create(:group, parent: group) }

      let(:form_group_selector) { '[data-testid="delayed-project-removal-form-group"]' }
      let(:setting_field_selector) { '[data-testid="delayed-project-removal-checkbox"]' }
      let(:setting_path) { edit_group_path(group, anchor: 'js-permissions-settings') }
      let(:group_path) { edit_group_path(group) }
      let(:subgroup_path) { edit_group_path(subgroup) }
      let(:click_save_button) { save_permissions_group }
    end

    describe 'immediately deleting a project marked for deletion', :js do
      before do
        create(:group_deletion_schedule, group: group, marked_for_deletion_on: 2.days.from_now)

        visit edit_group_path(group)
      end

      it 'deletes the project immediately', :sidekiq_inline do
        expect { remove_with_confirm('Remove group', group.path) }.to change { Group.count }.by(-1)

        expect(page).to have_content "scheduled for deletion"
      end

      def remove_with_confirm(button_text, confirm_with, confirm_button_text = 'Confirm')
        click_button button_text
        fill_in 'confirm_name_input', with: confirm_with
        click_button confirm_button_text
      end
    end
  end

  context 'when custom_project_templates feature' do
    let!(:subgroup) { create(:group, :public, parent: group) }
    let!(:subgroup_1) { create(:group, :public, parent: subgroup) }

    shared_examples 'shows custom project templates settings' do
      it 'shows the custom project templates selection menu' do
        expect(page).to have_content('Custom project templates')
      end

      context 'group selection menu', :js do
        before do
          slow_requests do
            find('#s2id_group_custom_project_templates_group_id').click
            wait_for_all_requests
          end
        end

        it 'shows only the subgroups' do
          # the default value of 0.2 from the slow_requests helper isn't
          # enough when this spec is exec along with other feature specs.
          sleep 0.5

          page.within('.select2-drop .select2-results') do
            results = find_all('.select2-result')

            expect(results.count).to eq(1)
            expect(results.last.text).to eq "#{nested_group.full_name}\n#{nested_group.full_path}"
          end
        end
      end
    end

    shared_examples 'does not show custom project templates settings' do
      it 'does not show the custom project templates selection menu' do
        expect(page).not_to have_content('Custom project templates')
      end
    end

    context 'is enabled' do
      before do
        stub_licensed_features(group_project_templates: true)
        visit edit_group_path(selected_group)
      end

      context 'when the group is a top parent group' do
        let(:selected_group) { group }
        let(:nested_group) { subgroup }

        it_behaves_like 'shows custom project templates settings'
      end

      context 'when the group is a subgroup' do
        let(:selected_group) { subgroup }
        let(:nested_group) { subgroup_1 }

        it_behaves_like 'shows custom project templates settings'
      end
    end

    context 'namespace plan is checked' do
      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: plan)
        stub_licensed_features(group_project_templates: true)
        allow(Gitlab::CurrentSettings.current_application_settings)
          .to receive(:should_check_namespace_plan?) { true }

        visit edit_group_path(selected_group)
      end

      context 'namespace is on the proper plan' do
        let(:plan) { create(:ultimate_plan) }

        context 'when the group is a top parent group' do
          let(:selected_group) { group }
          let(:nested_group) { subgroup }

          it_behaves_like 'shows custom project templates settings'
        end

        context 'when the group is a subgroup' do
          let(:selected_group) { subgroup }
          let(:nested_group) { subgroup_1 }

          it_behaves_like 'shows custom project templates settings'
        end
      end

      context 'is disabled for namespace' do
        let(:plan) { create(:bronze_plan) }

        context 'when the group is the top parent group' do
          let(:selected_group) { group }

          it_behaves_like 'does not show custom project templates settings'
        end

        context 'when the group is a subgroup' do
          let(:selected_group) { subgroup }

          it_behaves_like 'does not show custom project templates settings'
        end
      end
    end

    context 'is disabled' do
      before do
        stub_licensed_features(group_project_templates: false)
        visit edit_group_path(selected_group)
      end

      context 'when the group is the top parent group' do
        let(:selected_group) { group }

        it_behaves_like 'does not show custom project templates settings'
      end

      context 'when the group is a subgroup' do
        let(:selected_group) { subgroup }

        it_behaves_like 'does not show custom project templates settings'
      end
    end
  end

  describe 'merge request approval settings', :js do
    let_it_be(:approval_settings) do
      create(:group_merge_request_approval_setting, group: group, allow_author_approval: false)
    end

    context 'when feature flag is enabled and group is licensed' do
      before do
        stub_feature_flags(group_merge_request_approval_settings_feature_flag: true)
        stub_licensed_features(group_merge_request_approval_settings: true)
      end

      it 'allows to save settings' do
        visit edit_group_path(group)
        wait_for_all_requests

        expect(page).to have_content('Merge request approvals')

        within('[data-testid="merge-request-approval-settings"]') do
          click_button 'Expand'
          checkbox = find('[data-testid="prevent-author-approval"] > input')

          expect(checkbox).to be_checked

          checkbox.set(false)
          click_button 'Save changes'
          wait_for_all_requests
        end

        visit edit_group_path(group)
        wait_for_all_requests

        within('[data-testid="merge-request-approval-settings"]') do
          click_button 'Expand'
          expect(find('[data-testid="prevent-author-approval"] > input')).not_to be_checked
        end
      end
    end

    context 'when feature flag is disabled and group is not licensed' do
      before do
        stub_feature_flags(group_merge_request_approval_settings_feature_flag: false)
        stub_licensed_features(group_merge_request_approval_settings: false)
      end

      it 'is not visible' do
        visit edit_group_path(group)

        expect(page).not_to have_content('Merge request approvals')
      end
    end
  end

  describe 'email domain validation', :js do
    let(:domain_field_selector) { '[placeholder="Enter domain"]' }

    before do
      stub_licensed_features(group_allowed_email_domains: true)
    end

    def update_email_domains(new_domain)
      visit edit_group_path(group)

      find(domain_field_selector).set(new_domain)
      find(domain_field_selector).send_keys(:enter)
    end

    it 'is visible' do
      visit edit_group_path(group)

      expect(page).to have_content("Restrict membership by email domain")
    end

    it 'displays an error for invalid emails' do
      new_invalid_domain = "gitlab./com!"

      update_email_domains(new_invalid_domain)

      expect(page).to have_content("The domain you entered is misformatted")
    end

    it 'will save valid domains' do
      new_domain = "gitlab.com"

      update_email_domains(new_domain)

      expect(page).not_to have_content("The domain you entered is misformatted")

      click_button 'Save changes'
      wait_for_requests

      expect(page).to have_content("Group 'Foo bar' was successfully updated.")
    end
  end

  def save_permissions_group
    page.within('.gs-permissions') do
      click_button 'Save changes'
    end
  end
end
