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
end
