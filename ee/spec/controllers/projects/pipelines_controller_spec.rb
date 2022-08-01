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

  describe 'GET security' do
    context 'with a sast artifact' do
      before do
        create(:ee_ci_build, :sast, pipeline: pipeline)
      end

      context 'with feature enabled' do
        before do
          stub_licensed_features(sast: true, security_dashboard: true)

          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it 'redirects to the pipeline page with the security tab query param' do
          expect(response).to redirect_to(pipeline_path(pipeline, tab: 'security'))
        end
      end

      context 'with feature disabled' do
        before do
          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
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

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled' do
        before do
          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end
  end

  describe 'GET codequality_report' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    it 'redirects to pipeline path with dag tab query param' do
      get :codequality_report, params: { namespace_id: project.namespace, project_id: project, id: pipeline }

      expect(response).to redirect_to(pipeline_path(pipeline, tab: 'codequality_report'))
    end
  end

  describe 'GET licenses' do
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

        it 'redirects to the pipeline page with the licenses tab query param' do
          expect(response).to redirect_to(pipeline_path(pipeline, tab: 'licenses'))
        end
      end

      context 'with feature enabled json' do
        before do
          stub_licensed_features(license_scanning: true)
        end

        it 'will return license scanning report in json format' do
          expect(payload.size).to eq(pipeline.license_scanning_report.licenses.size)
          expect(payload.first.keys).to match_array(%w(name classification dependencies count url))
        end

        it 'will return mit license allowed status' do
          payload_mit = payload.find { |l| l['name'] == 'MIT' }
          expect(payload_mit['count']).to eq(pipeline.license_scanning_report.licenses.find { |x| x.name == 'MIT' }.count)
          expect(payload_mit['url']).to eq('http://opensource.org/licenses/mit-license')
          expect(payload_mit['classification']['approval_status']).to eq('allowed')
        end

        context 'approval_status' do
          subject(:status) { payload.find { |l| l['name'] == 'MIT' }.dig('classification', 'approval_status') }

          it { is_expected.to eq('allowed') }
        end

        it 'will return sorted by name' do
          expect(payload.first['name']).to eq('Apache 2.0')
          expect(payload.last['name']).to eq('unknown')
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

        it do
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

        it do
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

        it do
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
