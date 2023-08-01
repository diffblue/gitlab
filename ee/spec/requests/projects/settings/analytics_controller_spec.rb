# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::Settings::AnalyticsController, feature_category: :product_analytics_visualization do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group, project_setting: build(:project_setting)) }
  let_it_be(:pointer_project) { create(:project, group: group) }

  context 'as a maintainer' do
    before_all do
      project.add_maintainer(user)
    end

    before do
      sign_in(user)
    end

    describe 'GET show' do
      subject do
        get project_settings_analytics_path(project)
      end

      it 'renders analytics settings' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it 'is unavailable when the combined_analytics_dashboards feature flag is disabled' do
        stub_feature_flags(combined_analytics_dashboards: false)

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'PATCH update' do
      it 'redirects with expected flash' do
        params = {
          project: {
            project_setting_attributes: {
              cube_api_key: 'cube_api_key'
            }
          }
        }
        patch project_settings_analytics_path(project, params)

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_settings_analytics_path(project))
        expect(flash[:toast]).to eq("Analytics settings for '#{project.name}' were successfully updated.")
      end

      it 'updates product analytics settings' do
        params = {
          project: {
            project_setting_attributes: {
              product_analytics_configurator_connection_string: 'https://test:test@configurator.example.com',
              product_analytics_data_collector_host: 'https://collector.example.com',
              product_analytics_clickhouse_connection_string: 'https://test:test@clickhouse.example.com',
              cube_api_base_url: 'https://cube.example.com',
              cube_api_key: 'cube_api_key'
            }
          }
        }

        expect do
          patch project_settings_analytics_path(project, params)
        end.to change {
          project.reload.project_setting.product_analytics_configurator_connection_string
        }.to(
          params.dig(:project, :project_setting_attributes, :product_analytics_configurator_connection_string)
        ).and change {
          project.reload.project_setting.product_analytics_data_collector_host
        }.to(
          params.dig(:project, :project_setting_attributes, :product_analytics_data_collector_host)
        ).and change {
          project.reload.project_setting.product_analytics_clickhouse_connection_string
        }.to(
          params.dig(:project, :project_setting_attributes, :product_analytics_clickhouse_connection_string)
        ).and change {
          project.reload.project_setting.cube_api_base_url
        }.to(params.dig(:project, :project_setting_attributes, :cube_api_base_url)).and change {
          project.reload.project_setting.cube_api_key
        }.to(params.dig(:project, :project_setting_attributes, :cube_api_key))
      end

      it 'updates dashboard pointer project reference' do
        params = {
          project: {
            analytics_dashboards_pointer_attributes: {
              target_project_id: pointer_project.id
            }
          }
        }

        expect do
          patch project_settings_analytics_path(project, params)
        end.to change {
          project.reload.analytics_dashboards_configuration_project
        }.to(pointer_project)
      end

      context 'when save is unsuccessful' do
        before do
          allow_next_instance_of(::Projects::UpdateService) do |instance|
            allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'failed'))
          end
        end

        it 'redirects back to form with error' do
          params = {
            project: {
              project_setting_attributes: {
                cube_api_key: 'cube_api_key'
              }
            }
          }
          patch project_settings_analytics_path(project, params)

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(project_settings_analytics_path(project))
          expect(flash[:alert]).to eq('failed')
        end
      end
    end
  end
end
