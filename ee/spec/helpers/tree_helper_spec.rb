# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TreeHelper, feature_category: :source_code_management do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { build_stubbed(:project, :repository) }
  let(:sha) { 'c1c67abbaf91f624347bb3ae96eabe3a1b742478' }

  let_it_be(:user) { build_stubbed(:user) }

  describe '#vue_file_list_data' do
    before do
      project.add_developer(user)
      allow(helper).to receive(:current_user).and_return(user)
      sign_in(user)
    end

    it 'returns a list of attributes related to the project' do
      expect(helper.vue_file_list_data(project, sha)).to include(
        project_path: project.full_path,
        project_short_path: project.path,
        ref: sha,
        escaped_ref: sha,
        full_name: project.name_with_namespace,
        resource_id: project.to_global_id,
        user_id: user.to_global_id,
        explain_code_available: 'false'
      )
    end
  end

  describe '#web_ide_button_data' do
    before do
      allow(helper).to receive(:project_to_use).and_return(project)
      allow(helper).to receive(:project_ci_pipeline_editor_path).and_return('')
    end

    it 'includes new_workspace_path  and project id properties' do
      options = {}

      expect(helper.web_ide_button_data(options)).to include(
        new_workspace_path: new_remote_development_workspace_path,
        project_id: project.id
      )
    end
  end
end
