# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::ProjectMembersController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, namespace: namespace) }
  let(:namespace) { create :group }

  describe 'POST apply_import' do
    subject(:apply_import) do
      post(:apply_import, params: {
        namespace_id: project.namespace,
        project_id: project,
        source_project_id: another_project.id
      })
    end

    let(:another_project) { create(:project, :private) }
    let(:member) { create(:user) }

    before do
      project.add_maintainer(user)
      another_project.add_guest(member)
      sign_in(user)
    end

    context 'when user can access source project members' do
      before do
        another_project.add_guest(user)
      end

      context 'and the project group has membership lock enabled' do
        before do
          project.namespace.update!(membership_lock: true)
        end

        it 'responds with 403' do
          apply_import

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'GET import' do
    subject(:import) do
      get :import, params: {
        namespace_id: project.namespace,
        project_id: project
      }
    end

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'when project group has membership lock enabled' do
      before do
        project.namespace.update!(membership_lock: true)
      end

      it 'responds with 403' do
        import

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
