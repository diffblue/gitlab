# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
  let_it_be(:mit) { create(:software_license, :mit) }

  before do
    project.add_developer(user)

    sign_in(user)
  end

  describe 'GET security', feature_category: :vulnerability_management do
    context 'with a sast artifact' do
      before do
        create(:ee_ci_build, :sast, pipeline: pipeline)
      end

      context 'with feature enabled' do
        before do
          stub_licensed_features(sast: true, security_dashboard: true)

          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it 'responds with a 200 and show the template' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template :show
        end
      end

      context 'with feature disabled' do
        before do
          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it 'redirects to the pipeline page' do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end

    context 'without sast artifact' do
      context 'with feature enabled' do
        before do
          stub_licensed_features(sast: true)

          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it 'redirects to the pipeline page' do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled' do
        before do
          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it 'redirects to the pipeline page' do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end
  end

  describe 'GET codequality_report', feature_category: :code_quality do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    it 'renders the show template' do
      get :codequality_report, params: { namespace_id: project.namespace, project_id: project, id: pipeline }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template :show
    end
  end

  describe 'GET licenses', feature_category: :software_composition_analysis do
    let(:licenses_with_html) { get :licenses, format: :html, params: { namespace_id: project.namespace, project_id: project, id: pipeline } }
    let(:licenses_with_json) { get :licenses, format: :json, params: { namespace_id: project.namespace, project_id: project, id: pipeline } }
    let!(:software_license_policy) { create(:software_license_policy, software_license: mit, project: project) }

    let(:payload) { Gitlab::Json.parse(licenses_with_json.body) }

    context 'with a cyclonedx report' do
      let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
      let_it_be(:report) { create(:ee_ci_job_artifact, :cyclonedx, job: build) }

      context 'with feature enabled' do
        before do
          stub_licensed_features(license_scanning: true)
        end

        context 'when querying uncompressed package metadata' do
          before do
            stub_feature_flags(compressed_package_metadata_query: false)

            create(:pm_package_version_license, :with_all_relations, name: "esutils", purl_type: "npm",
              version: "2.0.3", license_name: "BSD-2-Clause")
            create(:pm_package_version_license, :with_all_relations, name: "github.com/astaxie/beego", purl_type: "golang",
              version: "v1.10.0", license_name: "Apache-2.0")
            create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem",
              version: "1.8.0", license_name: "MIT")
          end

          context 'with html' do
            before do
              licenses_with_html
            end

            it 'responds with a 200 and show the template' do
              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to render_template :show
            end
          end

          context 'with json' do
            let(:scanner) { ::Gitlab::LicenseScanning.scanner_for_pipeline(project, pipeline) }

            it 'returns license scanning report in json format' do
              expect(payload.size).to eq(scanner.report.licenses.size)
              expect(payload.first.keys).to match_array(%w(name classification dependencies count url))
            end

            it 'returns MIT license allowed status' do
              payload_mit = payload.find { |l| l['name'] == 'MIT' }
              expect(payload_mit['count']).to eq(scanner.report.licenses.find { |x| x.name == 'MIT' }.count)
              expect(payload_mit['url']).to eq("https://spdx.org/licenses/MIT.html")
              expect(payload_mit['classification']['approval_status']).to eq('allowed')
            end

            context 'approval_status' do
              subject(:status) { payload.find { |l| l['name'] == 'MIT' }.dig('classification', 'approval_status') }

              it { is_expected.to eq('allowed') }
            end

            it 'returns the JSON license data sorted by license name' do
              expect(payload.pluck('name')).to eq([
                'Apache 2.0 License',
                'BSD-2-Clause',
                'MIT',
                'unknown'
              ])
            end

            it 'returns a JSON representation of the license data' do
              expect(payload).to be_present

              payload.each do |item|
                expect(item['name']).to be_present
                expect(item['classification']).to have_key('id')
                expect(item.dig('classification', 'approval_status')).to be_present
                expect(item.dig('classification', 'name')).to be_present
                expect(item).to have_key('dependencies')
                item['dependencies'].each do |dependency|
                  expect(dependency['name']).to be_present
                end
                expect(item['count']).to be_present
                expect(item).to have_key('url')
              end
            end
          end
        end

        context 'when querying compressed package metadata' do
          before do
            create(:pm_package, name: "esutils", purl_type: "npm",
              other_licenses: [{ license_names: ["BSD-2-Clause"], versions: ["2.0.3"] }])
            create(:pm_package, name: "github.com/astaxie/beego", purl_type: "golang",
              other_licenses: [{ license_names: ["Apache-2.0"], versions: ["v1.10.0"] }])
            create(:pm_package, name: "nokogiri", purl_type: "gem",
              other_licenses: [{ license_names: ["MIT"], versions: ["1.8.0"] }])
          end

          context 'with html' do
            before do
              licenses_with_html
            end

            it 'responds with a 200 and show the template' do
              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to render_template :show
            end
          end

          context 'with json' do
            let(:scanner) { ::Gitlab::LicenseScanning.scanner_for_pipeline(project, pipeline) }

            it 'returns license scanning report in json format' do
              expect(payload.size).to eq(scanner.report.licenses.size)
              expect(payload.first.keys).to match_array(%w(name classification dependencies count url))
            end

            it 'returns MIT license allowed status' do
              payload_mit = payload.find { |l| l['name'] == 'MIT' }
              expect(payload_mit['count']).to eq(scanner.report.licenses.find { |x| x.name == 'MIT' }.count)
              expect(payload_mit['url']).to eq("https://spdx.org/licenses/MIT.html")
              expect(payload_mit['classification']['approval_status']).to eq('allowed')
            end

            context 'approval_status' do
              subject(:status) { payload.find { |l| l['name'] == 'MIT' }.dig('classification', 'approval_status') }

              it { is_expected.to eq('allowed') }
            end

            it 'returns the JSON license data sorted by license name' do
              expect(payload.pluck('name')).to eq([
                'Apache 2.0 License',
                'BSD-2-Clause',
                'Default License 2.1',
                'MIT',
                'unknown'
              ])
            end

            it 'returns a JSON representation of the license data' do
              expect(payload).to be_present

              payload.each do |item|
                expect(item['name']).to be_present
                expect(item['classification']).to have_key('id')
                expect(item.dig('classification', 'approval_status')).to be_present
                expect(item.dig('classification', 'name')).to be_present
                expect(item).to have_key('dependencies')
                item['dependencies'].each do |dependency|
                  expect(dependency['name']).to be_present
                end
                expect(item['count']).to be_present
                expect(item).to have_key('url')
              end
            end
          end
        end
      end
    end

    context 'without a cyclonedx report' do
      context 'with feature enabled' do
        before do
          stub_licensed_features(license_scanning: true)
          licenses_with_html
        end

        it 'redirects to the pipeline page' do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature enabled json' do
        before do
          stub_licensed_features(license_scanning: true)
          licenses_with_json
        end

        it 'will return 404'  do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with feature disabled' do
        before do
          licenses_with_html
        end

        it 'redirects to the pipeline page' do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled json' do
        before do
          licenses_with_json
        end

        it 'will return 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
