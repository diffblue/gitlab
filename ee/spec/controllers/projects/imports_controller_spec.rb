# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportsController, feature_category: :importers do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'POST #create' do
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
