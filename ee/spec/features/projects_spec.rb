# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project', :js do
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
end
