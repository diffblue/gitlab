# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PagesController, feature_category: :pages do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when max_pages_size param is specified' do
    let(:params) { { max_pages_size: 100 } }

    let(:request) do
      put :update, params: { namespace_id: project.namespace, project_id: project, project: params }
    end

    before do
      stub_licensed_features(pages_size_limit: true)
    end

    context 'when user is an admin' do
      let(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'updates max_pages_size' do
          request

          expect(project.reload.max_pages_size).to eq(100)
        end
      end

      context 'when admin mode is disabled' do
        it 'does not update max_pages_size' do
          request

          expect(project.reload.max_pages_size).to eq(nil)
        end
      end
    end

    context 'when user is not an admin' do
      it 'does not update max_pages_size' do
        request

        expect(project.reload.max_pages_size).to eq(nil)
      end
    end
  end

  context 'when updating pages_multiple_versions_enabled' do
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        project: {
          project_setting_attributes: {
            pages_multiple_versions_enabled: 'true'
          }
        }
      }
    end

    before do
      create(:project_setting, project: project, pages_multiple_versions_enabled: false)
    end

    context 'with pages_multiple_versions feature flag disabled' do
      it 'does not update pages unique domain' do
        stub_feature_flags(pages_multiple_versions_setting: false)

        expect { patch :update, params: request_params }
          .not_to change { project.project_setting.reload.pages_multiple_versions_enabled }
      end
    end

    context 'with pages_multiple_versions licensed feature disabled' do
      it 'does not update pages unique domain' do
        stub_licensed_features(pages_multiple_versions: false)

        expect { patch :update, params: request_params }
          .not_to change { project.project_setting.reload.pages_multiple_versions_enabled }
      end
    end

    context 'with pages_multiple_versions licensed feature and feature flag enabled' do
      before do
        stub_licensed_features(pages_multiple_versions: true)
        stub_feature_flags(pages_multiple_versions_setting: true)
      end

      context 'when user is a developer' do
        let(:developer) { create(:user) }

        before do
          project.add_developer(developer)
          sign_in(developer)
        end

        it 'does not update pages unique domain' do
          expect { patch :update, params: request_params }
            .not_to change { project.project_setting.reload.pages_multiple_versions_enabled }
        end
      end

      context 'when user is the project maintainer' do
        it 'updates pages_https_only and pages_multiple_versions and redirects back to pages settings' do
          expect { patch :update, params: request_params }
            .to change { project.project_setting.reload.pages_multiple_versions_enabled }
            .from(false).to(true)

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(project_pages_path(project))
        end

        context 'when it fails to update' do
          it 'adds an error message' do
            expect_next_instance_of(Projects::UpdateService) do |service|
              expect(service)
                .to receive(:execute)
                .and_return(status: :error, message: 'some error happened')
            end

            expect { patch :update, params: request_params }
              .not_to change { project.project_setting.reload.pages_multiple_versions_enabled }

            expect(response).to redirect_to(project_pages_path(project))
            expect(flash[:alert]).to eq('some error happened')
          end
        end
      end
    end
  end
end
