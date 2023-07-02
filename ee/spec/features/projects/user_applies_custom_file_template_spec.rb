# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project', :js, feature_category: :groups_and_projects do
  let(:template_text) { 'Custom license template content' }
  let(:group) { create(:group) }
  let(:template_project) { create(:project, :custom_repo, namespace: group, files: { 'LICENSE/custom.txt' => template_text }) }
  let(:project) { create(:project, :empty_repo, namespace: group) }
  let(:developer) { create(:user) }

  describe 'Custom file templates' do
    before do
      project.add_developer(developer)
      gitlab_sign_in(developer)
    end

    it 'allows file creation from an instance template' do
      stub_licensed_features(custom_file_templates: true)
      stub_ee_application_setting(file_template_project: template_project)

      visit project_new_blob_path(project, 'master', file_name: 'LICENSE')

      select_template('custom')

      wait_for_requests

      expect(page).to have_content(template_text)
    end

    it 'allows file creation from a group template' do
      stub_licensed_features(custom_file_templates_for_namespace: true)
      group.update_columns(file_template_project_id: template_project.id)

      visit project_new_blob_path(project, 'master', file_name: 'LICENSE')

      select_template('custom')

      wait_for_requests

      expect(page).to have_content(template_text)
    end
  end

  def select_template(name)
    click_button 'Apply a template'
    find('.gl-new-dropdown-contents li', text: name).click
  end
end
