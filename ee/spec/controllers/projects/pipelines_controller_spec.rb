# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

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

  describe 'GET licenses', feature_category: :license_compliance do
    let(:licenses_with_html) { get :licenses, format: :html, params: { namespace_id: project.namespace, project_id: project, id: pipeline } }
    let(:licenses_with_json) { get :licenses, format: :json, params: { namespace_id: project.namespace, project_id: project, id: pipeline } }
    let!(:mit_license) { create(:software_license, :mit) }
    let!(:software_license_policy) { create(:software_license_policy, software_license: mit_license, project: project) }

    let(:payload) { Gitlab::Json.parse(licenses_with_json.body) }

    context 'with a license scanning artifact' do
      before do
        build = create(:ci_build, pipeline: pipeline)
        create(:ee_ci_job_artifact, :license_scanning, job: build)
      end

      context 'with feature enabled' do
        before do
          stub_licensed_features(license_scanning: true)
          licenses_with_html
        end

        context 'when the license_scanning_sbom_scanner feature flag is false' do
          before_all do
            stub_feature_flags(license_scanning_sbom_scanner: false)
          end

          it 'responds with a 200 and show the template' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template :show
          end
        end

        context 'when the license_scanning_sbom_scanner feature flag is true' do
          let(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

          it 'responds with a 200 and shows the template' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template :show
          end
        end
      end

      context 'with feature enabled json' do
        before do
          stub_licensed_features(license_scanning: true)
        end

        context 'when the license_scanning_sbom_scanner feature flag is false' do
          before do
            stub_feature_flags(license_scanning_sbom_scanner: false)
          end

          it 'returns license scanning report in json format' do
            expect(payload.size).to eq(pipeline.license_scanning_report.licenses.size)
            expect(payload.first.keys).to match_array(%w(name classification dependencies count url))
          end

          it 'returns MIT license allowed status' do
            payload_mit = payload.find { |l| l['name'] == 'MIT' }
            expect(payload_mit['count']).to eq(pipeline.license_scanning_report.licenses.find { |x| x.name == 'MIT' }.count)
            expect(payload_mit['url']).to eq('http://opensource.org/licenses/mit-license')
            expect(payload_mit['classification']['approval_status']).to eq('allowed')
          end

          context 'approval_status' do
            subject(:status) { payload.find { |l| l['name'] == 'MIT' }.dig('classification', 'approval_status') }

            it { is_expected.to eq('allowed') }
          end

          it 'returns the JSON license data sorted by license name' do
            expect(payload.pluck('name')).to eq([
              'Apache 2.0',
              'MIT',
              'New BSD',
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

        context 'when the license_scanning_sbom_scanner feature flag is true' do
          let_it_be(:project) { create(:project, :repository) }
          let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

          before do
            # Seed the database with licenses for some of the components using the deprecated
            # license scanning artifact as a source.
            components = Gitlab::LicenseScanning::PipelineComponents.new(pipeline: pipeline).fetch
            components.each do |c|
              licenses = []
              pipeline.license_scanning_report.licenses.each do |license|
                license.dependencies.each { |dep| licenses << license.name if c.name == dep.name }
              end

              licenses.each do |license_name|
                create(:pm_package_version_license, :with_all_relations, name: c.name, purl_type: c.purl_type, version: c.version, license_name: license_name)
              end
            end
          end

          it 'returns license scanning report in json format' do
            expect(payload.size).to eq(4)
            expect(payload.first.keys).to match_array(%w(name classification dependencies count url))
          end

          it 'returns MIT license allowed status' do
            payload_mit = payload.find { |l| l['name'] == 'MIT' }
            expect(payload_mit['count']).to eq(13)
            expect(payload_mit['url']).to be_empty
            expect(payload_mit['classification']['approval_status']).to eq('allowed')
          end

          context 'approval_status' do
            subject(:status) { payload.find { |l| l['name'] == 'MIT' }.dig('classification', 'approval_status') }

            it { is_expected.to eq('allowed') }
          end

          it 'returns the JSON license data sorted by license name' do
            expect(payload.pluck('name')).to eq([
              'Apache 2.0',
              'MIT',
              'New BSD',
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

        context "when not authorized" do
          before do
            allow(controller).to receive(:can?).and_call_original
            allow(controller).to receive(:can?).with(user, :read_licenses, project).and_return(false)

            licenses_with_json
          end

          specify { expect(response).to have_gitlab_http_status(:not_found) }
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

        it 'will not return report' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'without license scanning artifact' do
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
