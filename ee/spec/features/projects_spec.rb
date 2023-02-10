# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project', :js, feature_category: :projects do
  describe 'immediately deleting a project marked for deletion' do
    let(:project) { create(:project, marked_for_deletion_at: Date.current) }
    let(:user) { project.first_owner }

    before do
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)

      sign_in user
      visit edit_project_path(project)
    end

    it 'deletes the project immediately', :sidekiq_inline do
      expect { remove_with_confirm('Delete project', project.path_with_namespace, 'Yes, delete project') }.to change { Project.count }.by(-1)

      expect(page).to have_content "Project '#{project.full_name}' is in the process of being deleted."
      expect(Project.all.count).to be_zero
    end

    def remove_with_confirm(button_text, confirm_with, confirm_button_text = 'Confirm')
      click_button button_text
      fill_in 'confirm_name_input', with: confirm_with
      click_button confirm_button_text
    end
  end

  describe 'delete project container text' do
    using RSpec::Parameterized::TableSyntax
    let(:group_settings) { create(:namespace_settings, delayed_project_removal: delayed_project_removal) }
    let(:group) { create(:group, :public, namespace_settings: group_settings) }
    let(:project) { create(:project, group: group) }
    let(:user) { create(:user) }

    where(:feature_available_on_instance, :delayed_project_removal, :shows_adjourned_delete) do
      true  | nil  | false
      true  | true | true
      false | true | false
      false | nil  | false
    end

    before do
      stub_application_setting(deletion_adjourned_period: 7)
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: feature_available_on_instance)
      group.add_member(user, Gitlab::Access::OWNER)

      sign_in user
      visit edit_project_path(project)
    end

    with_them do
      if params[:shows_adjourned_delete]
        it 'renders the marked for removal message' do
          freeze_time do
            deletion_date = (Time.now.utc + ::Gitlab::CurrentSettings.deletion_adjourned_period.days).strftime('%F')

            expect(page).to have_content("This action deletes #{project.path_with_namespace} on #{deletion_date} and everything this project contains.")

            click_button "Delete project"

            expect(page).to have_content("This project can be restored until #{deletion_date}.")
          end
        end
      else
        it 'renders the permanently delete message' do
          expect(page).to have_content("This action deletes #{project.path_with_namespace} and everything this project contains. There is no going back.")

          click_button "Delete project"

          expect(page).not_to have_content(/This project can be restored/)
        end
      end
    end
  end

  describe 'storage_enforcement_banner', :js do
    let_it_be_with_refind(:group) { create(:group, :with_root_storage_statistics) }
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:storage_banner_text) { "A namespace storage limit will soon be enforced" }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(enforce_namespace_storage_limit: true)

      group.root_storage_statistics.update!(
        storage_size: ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP
      )
      group.add_maintainer(user)
      sign_in(user)
    end

    context 'with storage_enforcement_date set' do
      let_it_be(:storage_enforcement_date) { Date.today + 30 }

      before do
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
      end

      it 'displays the banner in the project page' do
        visit project_path(project)
        have_text storage_banner_text
      end

      context 'when in a subgroup project page' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:project) { create(:project, namespace: subgroup) }

        it 'displays the banner' do
          visit project_path(project)
          have_text storage_banner_text
        end
      end

      context 'when in a user namespace project page' do
        let_it_be_with_refind(:project) { create(:project, namespace: user.namespace) }

        before do
          create(
            :namespace_root_storage_statistics,
            namespace: user.namespace,
            storage_size: ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP
          )

          allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
            allow(user_namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
          end
        end

        it 'displays the banner' do
          visit project_path(project)
          have_text storage_banner_text
        end
      end

      it 'does not display the banner in a paid group project page' do
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:paid?).and_return(true)
        end
        visit project_path(project)
        expect(page).not_to have_text storage_banner_text
      end

      it 'does not display the banner if user has previously closed unless threshold has changed', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/390917' do
        visit project_path(project)
        have_text storage_banner_text
        find('.js-storage-enforcement-banner [data-testid="close-icon"]').click
        wait_for_requests
        page.refresh
        expect(page).not_to have_text storage_banner_text

        storage_enforcement_date = Date.today + 13
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
        page.refresh
        have_text storage_banner_text
      end
    end

    context 'with storage_enforcement_date not set' do
      before do
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:storage_enforcement_date).and_return(nil)
        end
      end

      it 'does not display the banner in the group page' do
        stub_feature_flags(namespace_storage_limit_bypass_date_check: false)
        visit project_path(project)
        expect(page).not_to have_text storage_banner_text
      end
    end
  end
end
