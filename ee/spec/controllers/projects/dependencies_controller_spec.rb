# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DependenciesController, feature_category: :dependency_management do
  describe 'GET #index' do
    let_it_be(:developer) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :private) }

    let(:params) { { namespace_id: project.namespace, project_id: project } }

    before do
      project.add_developer(developer)
      project.add_guest(guest)

      sign_in(user)
    end

    include_context '"Security & Compliance" permissions' do
      let(:user) { developer }
      let(:valid_request) { get :index, params: params }
    end

    context 'with authorized user' do
      context 'when feature is available' do
        before do
          stub_licensed_features(dependency_scanning: true, license_scanning: true, security_dashboard: true)
        end

        context 'when requesting HTML' do
          render_views
          let(:user) { developer }

          before do
            get :index, params: params, format: :html
          end

          it { expect(response).to have_gitlab_http_status(:ok) }

          it 'renders the side navigation with the correct submenu set as active' do
            expect(response.body).to have_active_sub_navigation('Dependency list')
          end
        end

        context 'with existing report' do
          let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

          before do
            get :index, params: params, format: :json
          end

          shared_examples 'paginated list' do
            it 'returns paginated list' do
              expect(json_response['dependencies'].length).to eq(20)
              expect(response).to include_pagination_headers
            end
          end

          context 'without pagination params' do
            let(:user) { developer }

            context 'with dependency_list_exporter feature flag disabled' do
              before do
                stub_feature_flags(dependency_list_exporter: false)
                get :index, params: params, format: :json
              end

              it 'returns a hash with dependencies not paginated' do
                expect(json_response).to be_a(Hash)
                expect(json_response['dependencies'].length).to eq(21)
              end
            end

            context 'with dependency_list_exporter feature flag enabled' do
              include_examples 'paginated list'
            end

            it 'returns status ok' do
              expect(json_response['report']['status']).to eq('ok')
            end

            it 'returns job path' do
              job_path = "/#{project.full_path}/builds/#{pipeline.builds.last.id}"

              expect(json_response['report']['job_path']).to eq(job_path)
            end

            it 'returns success code' do
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'with params' do
            let_it_be(:finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata, :with_pipeline) }
            let_it_be(:finding_pipeline) { create(:vulnerabilities_finding_pipeline, finding: finding, pipeline: pipeline) }
            let_it_be(:other_finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata, package: 'debug', file: 'yarn/yarn.lock', version: '1.0.5', raw_severity: 'Unknown') }
            let_it_be(:other_pipeline) { create(:vulnerabilities_finding_pipeline, finding: other_finding, pipeline: pipeline) }

            context 'with sorting params' do
              let(:user) { developer }

              context 'when sorted by packager' do
                let(:params) do
                  {
                    namespace_id: project.namespace,
                    project_id: project,
                    sort_by: 'packager',
                    sort: 'desc',
                    page: 1
                  }
                end

                it 'returns sorted list' do
                  expect(json_response['dependencies'].first['packager']).to eq('Ruby (Bundler)')
                  expect(json_response['dependencies'].last['packager']).to eq('JavaScript (Yarn)')
                end

                it 'return 20 dependencies' do
                  expect(json_response['dependencies'].length).to eq(20)
                end
              end

              context 'when sorted by severity' do
                let(:params) do
                  {
                    namespace_id: project.namespace,
                    project_id: project,
                    sort_by: 'severity',
                    page: 1
                  }
                end

                it 'returns sorted list' do
                  expect(json_response['dependencies'].first['name']).to eq('nokogiri')
                  expect(json_response['dependencies'].second['name']).to eq('debug')
                end
              end
            end

            context 'with filter by vulnerable' do
              let(:params) do
                {
                  namespace_id: project.namespace,
                  project_id: project,
                  filter: 'vulnerable'
                }
              end

              context 'with authorized user to see vulnerabilities' do
                let(:user) { developer }

                it 'return vulnerable dependencies' do
                  expect(json_response['dependencies'].length).to eq(2)
                end

                it 'returns vulnerability params' do
                  dependency = json_response['dependencies'].find { |dep| dep['name'] == 'nokogiri' }
                  vulnerability = dependency['vulnerabilities'].first
                  path = "/security/vulnerabilities/#{finding.vulnerability_id}"

                  expect(vulnerability['name']).to eq('Vulnerabilities in libxml2 in nokogiri')
                  expect(vulnerability['id']).to eq(finding.vulnerability_id)
                  expect(vulnerability['url']).to end_with(path)
                end
              end
            end

            context 'with pagination params' do
              let(:user) { developer }
              let(:params) { { namespace_id: project.namespace, project_id: project, page: 1 } }

              context 'with dependency_list_exporter feature flag enabled' do
                include_examples 'paginated list'
              end

              context 'with dependency_list_exporter feature flag disabled' do
                before do
                  stub_feature_flags(dependency_list_exporter: false)
                  get :index, params: params, format: :json
                end

                include_examples 'paginated list'
              end
            end
          end
        end

        context 'with found license report' do
          let(:user) { developer }
          let(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }
          let(:license_build) { create(:ee_ci_build, :success, :license_scanning, pipeline: pipeline) }

          before do
            pipeline.builds << license_build

            get :index, params: params, format: :json
          end

          it 'include license information to response' do
            nokogiri = json_response['dependencies'].find { |dep| dep['name'] == 'nokogiri' }

            expect(nokogiri['licenses']).not_to be_empty
          end
        end

        context 'with a report of the wrong type' do
          let(:user) { developer }
          let!(:pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }

          before do
            get :index, params: params, format: :json
          end

          it 'returns job_not_set_up status' do
            expect(json_response['report']['status']).to eq('job_not_set_up')
          end

          it 'returns a nil job_path' do
            expect(json_response['report']['job_path']).to be_nil
          end
        end

        context 'when report doesn\'t have dependency list field' do
          let(:user) { developer }

          let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }
          let_it_be(:finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata, :with_pipeline) }
          let_it_be(:finding_pipeline) { create(:vulnerabilities_finding_pipeline, finding: finding, pipeline: pipeline) }

          before do
            get :index, params: params, format: :json
          end

          it 'returns dependencies with vulnerabilities' do
            expect(json_response['dependencies'].count).to eq(1)
            nokogiri = json_response['dependencies'].first
            expect(nokogiri).not_to be_nil
            expect(nokogiri['vulnerabilities'].first).to include({ "id" => finding.vulnerability_id, "name" => "Vulnerabilities in libxml2 in nokogiri", "severity" => "high" })
            expect(json_response['report']['status']).to eq('ok')
          end
        end

        context 'when job failed' do
          let(:user) { developer }
          let!(:pipeline) { create(:ee_ci_pipeline, :success, project: project) }
          let!(:build) { create(:ee_ci_build, :dependency_list, :failed, :allowed_to_fail) }

          before do
            pipeline.builds << build

            get :index, params: params, format: :json
          end

          it 'returns job_failed status' do
            expect(json_response['report']['status']).to eq('job_failed')
          end
        end
      end

      context 'when licensed feature is unavailable' do
        let(:user) { developer }

        it 'returns 403 for a JSON request' do
          get :index, params: params, format: :json

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'returns a 404 for an HTML request' do
          get :index, params: params, format: :html

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      let(:user) { guest }

      before do
        stub_licensed_features(dependency_scanning: true)
        project.add_guest(user)
      end

      it 'returns 403 for a JSON request' do
        get :index, params: params, format: :json

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns a 404 for an HTML request' do
        get :index, params: params, format: :html

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
