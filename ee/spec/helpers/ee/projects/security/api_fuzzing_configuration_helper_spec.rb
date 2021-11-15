# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ApiFuzzingConfigurationHelper do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:security_configuration_path) { project_security_configuration_path(project) }
  let(:full_path) { project.full_path }
  let(:gitlab_ci_yaml_edit_path) { Rails.application.routes.url_helpers.project_ci_pipeline_editor_path(project) }
  let(:api_fuzzing_documentation_path) { help_page_path('user/application_security/api_fuzzing/index') }
  let(:api_fuzzing_authentication_documentation_path) { help_page_path('user/application_security/api_fuzzing/index', anchor: 'authentication') }
  let(:ci_variables_documentation_path) { help_page_path('ci/variables/index') }
  let(:project_ci_settings_path) { project_settings_ci_cd_path(project) }

  subject { helper.api_fuzzing_configuration_data(project) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#api_fuzzing_configuration_data' do
    context 'user with admin_pipeline permissions' do
      before do
        allow(helper).to receive(:can?).with(user, :admin_pipeline, project).and_return(true)
      end

      it {
        is_expected.to eq(
          security_configuration_path: security_configuration_path,
          full_path: full_path,
          gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
          api_fuzzing_documentation_path: api_fuzzing_documentation_path,
          api_fuzzing_authentication_documentation_path: api_fuzzing_authentication_documentation_path,
          ci_variables_documentation_path: ci_variables_documentation_path,
          project_ci_settings_path: project_ci_settings_path,
          can_set_project_ci_variables: 'true'
        )
      }
    end

    context 'user without admin_pipeline permissions' do
      before do
        allow(helper).to receive(:can?).with(user, :admin_pipeline, project).and_return(false)
      end

      it {
        is_expected.to eq(
          security_configuration_path: security_configuration_path,
          full_path: full_path,
          gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
          api_fuzzing_documentation_path: api_fuzzing_documentation_path,
          api_fuzzing_authentication_documentation_path: api_fuzzing_authentication_documentation_path,
          ci_variables_documentation_path: ci_variables_documentation_path,
          project_ci_settings_path: project_ci_settings_path,
          can_set_project_ci_variables: 'false'
        )
      }
    end
  end
end
