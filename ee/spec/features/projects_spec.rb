# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project', :js do
  describe 'when creating from group template', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/222234' do
    let(:user) { create(:user) }
    let(:group) { create(:group, name: 'parent-group') }
    let(:template_subgroup) { create(:group, parent: group, name: 'template-subgroup') }
    let(:other_subgroup) { create(:group, parent: group, name: 'other-subgroup') }
    let(:template) { create(:project, namespace: template_subgroup) }

    before do
      stub_licensed_features(custom_project_templates: true)
      group.add_owner(user)
      group.update!(custom_project_templates_group_id: template_subgroup.id)
      sign_in user
    end

    it "defaults to correct namespace" do
      visit new_project_path
      find('[data-qa-selector="create_from_template_link"]').click
      find('.custom-group-project-templates-tab').click
      find("label[for=#{template.name}]").click

      expect(find('.js-select-namespace')).to have_content group.name
    end

    it "uses supplied namespace" do
      visit new_project_path(namespace_id: other_subgroup.id)
      find('[data-qa-selector="create_from_template_link"]').click
      find('.custom-group-project-templates-tab').click
      find("label[for=#{template.name}]").click

      expect(find('.js-select-namespace')).to have_content other_subgroup.name
    end
  end

  describe 'immediately deleting a project marked for deletion' do
    let(:project) { create(:project, marked_for_deletion_at: Date.current) }
    let(:user) { project.owner }

    before do
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)

      sign_in user
      visit edit_project_path(project)
    end

    it 'deletes the project immediately', :sidekiq_inline do
      expect { remove_with_confirm('Delete project', project.path, 'Yes, delete project') }.to change { Project.count }.by(-1)

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
