# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project creation via Registrations::GroupsProjectsController', type: :request,
                                                                               feature_category: :projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  describe 'POST #create' do
    let(:params) { { group: group_params, project: project_params } }
    let(:group_params) do
      {
        name: 'Group name',
        path: 'group-path',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s,
        setup_for_company: nil
      }
    end

    let(:project_params) do
      {
        name: 'New project',
        path: 'project-path',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE,
        initialize_with_readme: 'true'
      }
    end

    context 'with an authenticated user', :saas do
      before do
        sign_in(user)
      end

      context 'when group and project can be created' do
        it 'creates a group' do
          # 204 before creating learn gitlab in worker
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(150)

          expect { post users_sign_up_groups_projects_path, params: params }.to change { Group.count }.by(1)
        end
      end

      context 'when group already exists and project can be created' do
        before do
          group.add_owner(user)
        end

        let(:group_params) { { id: group.id } }

        it 'creates a project' do
          # queries: core project is 78 and learn gitlab is 76, which is now in background
          expect { post users_sign_up_groups_projects_path, params: params }.to change { Project.count }.by(1)
        end
      end
    end
  end
end
