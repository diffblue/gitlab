# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MirrorsController, feature_category: :source_code_management do
  let(:project) do
    create(
      :project, :repository,
      mirror: true,
      mirror_user: user,
      import_url: 'http://user:pass@test.url'
    )
  end

  let(:user) { create(:user) }

  describe 'updates the mirror URL' do
    before do
      project.add_maintainer(user)
      login_as(user)
    end

    it 'complains about passing an empty URL' do
      patch project_mirror_path(project),
        params: {
          project: {
            mirror: '1',
            import_url: '',
            mirror_trigger_builds: '0'
          }
        }

      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-push-remote-settings'))
      expect(flash[:alert]).to include("Import url can't be blank")
    end
  end
end
