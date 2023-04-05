# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::Settings::CiCdController, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent_group) }
  let_it_be(:project) { create(:project, group: group) }

  context 'as a maintainer' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    describe 'GET show' do
      let!(:protected_environment) { create(:protected_environment, project: project) }
      let!(:group_protected_environment) { create(:protected_environment, group: group, project: nil) }
      let!(:parent_group_protected_environment) { create(:protected_environment, group: parent_group, project: nil) }

      it 'renders group protected environments' do
        get :show, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
        expect(subject.view_assigns['group_protected_environments'])
          .to match_array([group_protected_environment, parent_group_protected_environment])
      end
    end

    describe 'PATCH update' do
      subject do
        patch :update, params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          project: params
        }
      end

      context 'when updating general settings' do
        context 'when allow_pipeline_trigger_approve_deployment is specified' do
          let(:params) { { allow_pipeline_trigger_approve_deployment: true } }

          it 'sets allow_pipeline_trigger_approve_deployment' do
            expect { subject }.to change {
              project.reload.allow_pipeline_trigger_approve_deployment
            }.from(false).to(true)
          end
        end
      end
    end
  end
end
