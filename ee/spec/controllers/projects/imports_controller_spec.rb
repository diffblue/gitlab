# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportsController, feature_category: :importers do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    sign_in(user)
  end

  context 'GET #show' do
    before do
      stub_licensed_features(custom_project_templates: true)

      project.import_state.update!(status: :started)
    end

    context 'when import type is gitlab_custom_project_template' do
      let(:project) do
        create(:project_empty_repo,
          import_type: 'gitlab_custom_project_template',
          import_url: 'https://github.com/vim/vim.git',
          namespace: group
        )
      end

      context 'when developer is allowed to create projects' do
        let(:group) { create(:group, project_creation_level: Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

        before do
          group.add_developer(user)
        end

        it 'returns 200 response' do
          get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

          expect(response).to have_gitlab_http_status(:success)
        end
      end

      context 'when developer is not allowed to create projects' do
        let(:group) { create(:group, project_creation_level: Gitlab::Access::MAINTAINER_PROJECT_ACCESS) }

        before do
          group.add_developer(user)
        end

        it 'returns 404 response' do
          get :show, params: { namespace_id: project.namespace.to_param, project_id: project }
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  context 'POST #create' do
    before do
      project.add_maintainer(user)
    end

    context 'mirror user is not the current user' do
      it 'only assigns the current user' do
        allow_next_instance_of(EE::Project) do |instance|
          allow(instance).to receive(:add_import_job)
        end

        new_user = create(:user)
        project.add_maintainer(new_user)

        post :create, params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          project: { mirror: true, mirror_user_id: new_user.id, import_url: 'http://local.dev' }
        }, format: :json

        expect(project.reload.mirror).to eq(true)
        expect(project.reload.mirror_user.id).to eq(user.id)
      end
    end
  end
end
