# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DependenciesController, feature_category: :dependency_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    context 'with HTML format' do
      subject { get group_dependencies_path(group_id: group.full_path) }

      context 'when security dashboard feature is enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
          stub_feature_flags(group_level_dependencies: true)
        end

        context 'and user is allowed to access group level dependencies' do
          before do
            group.add_developer(user)
          end

          it 'returns http status :ok' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'returns the correct template' do
            subject

            expect(assigns(:group)).to eq(group)
            expect(response).to render_template(:index)
            expect(response.body).to include('data-documentation-path')
            expect(response.body).to include('data-empty-state-svg-path')
            expect(response.body).to include('data-endpoint')
            expect(response.body).to include('data-support-documentation-path')
            expect(response.body).to include('data-export-endpoint')
          end

          context 'when feature flag group_level_dependencies is disabled' do
            before do
              stub_feature_flags(group_level_dependencies: false)
            end

            it 'return http status :not_found' do
              subject

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when user is not allowed to access group level dependencies' do
          it 'return http status :not_found' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when security dashboard feature is disabled' do
        it 'return http status :not_found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with JSON format' do
      subject { get group_dependencies_path(group_id: group.full_path), params: params, as: :json }

      let(:params) { { group_id: group.to_param } }

      context 'when security dashboard feature is enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
          stub_feature_flags(group_level_dependencies: true)
        end

        context 'and user is allowed to access group level dependencies' do
          let(:expected_response) do
            {
              'report' => {
                'status' => 'no_dependencies'
              },
              'dependencies' => []
            }
          end

          before do
            group.add_developer(user)
          end

          it 'returns http status :ok' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'returns the expected data' do
            subject

            expect(json_response).to eq(expected_response)
          end

          context 'with existing dependencies' do
            let_it_be(:project) { create(:project, group: group) }
            let_it_be(:sbom_occurrence_npm) { create(:sbom_occurrence, project: project, packager_name: 'npm') }
            let_it_be(:sbom_occurrence_bundler) { create(:sbom_occurrence, project: project, packager_name: 'bundler') }

            let(:expected_response) do
              {
                'report' => {
                  'status' => 'ok'
                },
                'dependencies' => [
                  {
                    'location' => sbom_occurrence_npm.location.as_json,
                    'name' => sbom_occurrence_npm.name,
                    'packager' => sbom_occurrence_npm.packager,
                    'version' => sbom_occurrence_npm.version,
                    'occurrence_count' => 1,
                    'project_count' => 1,
                    "project" => { "full_path" => project.full_path, "name" => project.name },
                    "component_id" => sbom_occurrence_npm.component_id
                  },
                  {
                    'location' => sbom_occurrence_bundler.location.as_json,
                    'name' => sbom_occurrence_bundler.name,
                    'packager' => sbom_occurrence_bundler.packager,
                    'version' => sbom_occurrence_bundler.version,
                    'occurrence_count' => 1,
                    'project_count' => 1,
                    "project" => { "full_path" => project.full_path, "name" => project.name },
                    "component_id" => sbom_occurrence_bundler.component_id
                  }
                ]
              }
            end

            it 'includes pagination headers in the response' do
              subject

              expect(response).to include_pagination_headers
            end

            it 'avoids N+1 database queries related to projects and routes' do
              control = ActiveRecord::QueryRecorder.new(skip_cached: false) { subject }

              project_routes_count = control.log.count do |entry|
                entry[/\Aselect.+routes.+from.+routes.+where.+routes(.+source_id|.+source_type.+project){2}/i]
              end
              project_count = control.log.count do |entry|
                entry[/\Aselect.+projects.+from.+projects.+where.+projects.+id/i]
              end

              expect(project_routes_count).to eq(1)
              expect(project_count).to eq(1)
            end

            context 'with sorting params' do
              context 'when sorted by packager' do
                let(:params) { { group_id: group.to_param, sort_by: 'packager', sort: 'desc' } }

                it 'returns sorted list' do
                  subject

                  expect(json_response['dependencies'].first['packager']).to eq('npm')
                  expect(json_response['dependencies'].last['packager']).to eq('bundler')
                end
              end

              context 'when sorted by name' do
                let(:params) { { group_id: group.to_param, sort_by: 'name', sort: 'asc' } }

                it 'returns sorted list' do
                  subject

                  expect(json_response['dependencies'].first['name']).to eq(sbom_occurrence_npm.name)
                  expect(json_response['dependencies'].last['name']).to eq(sbom_occurrence_bundler.name)
                end
              end
            end

            context 'with filtering params' do
              context 'when filtered by package managers' do
                let(:params) { { group_id: group.to_param, package_managers: ['npm'] } }

                it 'returns filtered list' do
                  subject

                  expect(json_response['dependencies'].pluck('packager')).to eq(['npm'])
                end
              end
            end
          end

          context 'when feature flag group_level_dependencies is disabled' do
            before do
              stub_feature_flags(group_level_dependencies: false)
            end

            it 'returns http status :forbidden' do
              subject

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end

        context 'when user is not allowed to access group level dependencies' do
          it 'returns http status :forbidden' do
            subject

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      context 'when security dashboard feature is disabled' do
        it 'returns http status :forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'GET locations' do
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:component) { create(:sbom_component) }
    let(:params) { { group_id: group.to_param, search: 'file', component_id: component.id } }

    subject { get locations_group_dependencies_path(group_id: group.full_path), params: params, as: :json }

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
        stub_feature_flags(group_level_dependencies: true)
      end

      context 'and user is allowed to access group level dependencies' do
        before do
          group.add_developer(user)
        end

        it 'returns http status :ok' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns empty array' do
          subject

          expect(json_response['locations']).to be_empty
        end

        context 'with existing matches' do
          let_it_be(:occurrence_npm) { create(:sbom_occurrence, component: component, project: project) }
          let_it_be(:source_npm) { occurrence_npm.source }
          let_it_be(:source_bundler) { create(:sbom_source, packager_name: 'bundler', input_file_path: 'Gemfile.lock') }
          let_it_be(:occurrence_bundler) do
            create(:sbom_occurrence, source: source_bundler, component: component, project: project)
          end

          let_it_be(:location_bundler) { occurrence_bundler.location }

          let(:expected_response) do
            [
              {
                'location' => {
                  "blob_path" => location_bundler[:blob_path],
                  "path" => location_bundler[:path]
                },
                'project' => {
                  "name" => project.name
                }
              }
            ]
          end

          it 'returns location related data' do
            subject

            expect(json_response['locations']).to eq(expected_response)
          end

          context 'without filtering params' do
            let(:params) { { group_id: group.to_param } }

            it 'returns empty array' do
              subject

              expect(json_response['locations']).to be_empty
            end
          end
        end

        context 'when feature flag group_level_dependencies is disabled' do
          before do
            stub_feature_flags(group_level_dependencies: false)
          end

          it 'returns http status :forbidden' do
            subject

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      context 'when user is not allowed to access group level dependencies' do
        it 'returns http status :forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when security dashboard feature is disabled' do
      it 'returns http status :forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
