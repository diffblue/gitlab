# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ServiceDeskController, feature_category: :service_desk do
  let_it_be(:project) do
    create(:project, :private, :custom_repo,
           service_desk_enabled: true, files: { '.gitlab/issue_templates/service_desk.md' => 'template' })
  end

  let_it_be(:template_project) { create(:project) }

  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'PUT service desk properties' do
    it 'sets file_template_project_id', :aggregate_failures do
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        issue_template_key: 'service_desk',
        file_template_project_id: template_project.id,
        format: :json
      }

      put namespace_project_service_desk_refresh_path(params)

      settings = project.service_desk_setting
      expect(settings).to be_present
      expect(settings.issue_template_key).to eq('service_desk')
      expect(json_response['template_file_missing']).to eq(false)
      expect(json_response['issue_template_key']).to eq('service_desk')
      expect(json_response['file_template_project_id']).to eq(template_project.id)
    end
  end
end
