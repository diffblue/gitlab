# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Scans::RunService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, :with_dast_submit_field, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, spider_timeout: 42, target_timeout: 21) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project, dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute' do
    subject do
      config_result = AppSec::Dast::ScanConfigs::BuildService.new(
        container: project,
        current_user: user,
        params: { branch: project.default_branch, dast_profile: dast_profile }
      ).execute

      described_class.new(project, user).execute(**config_result.payload)
    end

    let(:status) { subject.status }
    let(:pipeline) { subject.payload }
    let(:message) { subject.message }

    context 'when a user does not have access to the project' do
      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('Insufficient permissions')
      end
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(user)
      end

      it 'returns a success status' do
        expect(status).to eq(:success)
      end

      it 'returns a pipeline' do
        expect(pipeline).to be_a(Ci::Pipeline)
      end

      it 'creates a pipeline' do
        expect { subject }.to change(Ci::Pipeline, :count).by(1)
      end

      it 'associates the dast profile', :aggregate_failures do
        worker_class = AppSec::Dast::Scans::ConsistencyWorker
        allow(worker_class).to receive(:perform_async).and_call_original

        expect(pipeline.dast_profile).to eq(dast_profile)
        expect(worker_class).to have_received(:perform_async).with(pipeline.id, dast_profile.id)
      end

      it 'sets the pipeline ref to the branch' do
        expect(pipeline.ref).to eq(project.default_branch)
      end

      it 'sets the source to indicate an ondemand scan' do
        expect(pipeline.source).to eq('ondemand_dast_scan')
      end

      it 'creates a stage' do
        expect { subject }.to change(Ci::Stage, :count).by(1)
      end

      it 'creates a build' do
        expect { subject }.to change(Ci::Build, :count).by(1)
      end

      it 'sets the build name to indicate a DAST scan' do
        build = pipeline.builds.first
        expect(build.name).to eq('dast')
      end

      it 'creates a build with appropriate options' do
        build = pipeline.builds.first

        expected_options = {
          image: {
            name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION'
          },
          script: [
            '/analyze'
          ],
          artifacts: {
            reports: {
              dast: ['gl-dast-report.json']
            }
          },
          dast_configuration: { site_profile: dast_site_profile.name, scanner_profile: dast_scanner_profile.name }
        }

        expect(build.options).to eq(expected_options)
      end

      it 'creates a build with appropriate variables' do
        build = pipeline.builds.first

        expected_variables = [
          {
            key: 'DAST_AUTH_URL',
            value: dast_site_profile.auth_url,
            public: true,
            masked: false
          }, {
            key: 'DAST_DEBUG',
            value: String(dast_scanner_profile.show_debug_messages?),
            public: true,
            masked: false
          }, {
            key: 'DAST_EXCLUDE_URLS',
            value: dast_site_profile.excluded_urls.join(','),
            public: true,
            masked: false
          }, {
            key: 'DAST_FULL_SCAN_ENABLED',
            value: String(dast_scanner_profile.active?),
            public: true,
            masked: false
          }, {
            key: 'DAST_PASSWORD_FIELD',
            value: dast_site_profile.auth_password_field,
            public: true,
            masked: false
          }, {
            key: 'DAST_SPIDER_MINS',
            value: String(dast_scanner_profile.spider_timeout),
            public: true,
            masked: false
          }, {
            key: 'DAST_TARGET_AVAILABILITY_TIMEOUT',
            value: String(dast_scanner_profile.target_timeout),
            public: true,
            masked: false
          }, {
            key: 'DAST_USERNAME',
            value: dast_site_profile.auth_username,
            public: true,
            masked: false
          }, {
            key: 'DAST_USERNAME_FIELD',
            value: dast_site_profile.auth_username_field,
            public: true,
            masked: false
          }, {
            key: 'DAST_SUBMIT_FIELD',
            value: dast_site_profile.auth_submit_field,
            public: true,
            masked: false
          }, {
            key: 'DAST_USE_AJAX_SPIDER',
            value: String(dast_scanner_profile.use_ajax_spider?),
            public: true,
            masked: false
          }, {
            key: 'DAST_VERSION',
            value: '4',
            public: true,
            masked: false
          }, {
            key: 'DAST_WEBSITE',
            value: dast_site_profile.dast_site.url,
            public: true,
            masked: false
          }, {
            key: 'GIT_STRATEGY',
            value: 'none',
            public: true,
            masked: false
          }, {
            key: 'SECURE_ANALYZERS_PREFIX',
            value: '$CI_TEMPLATE_REGISTRY_HOST/security-products',
            public: true,
            masked: false
          }
        ]

        expect(build.variables.to_runner_variables).to include(*expected_variables)
      end

      context 'when the pipeline fails to save' do
        let(:fake_pipeline) { instance_double 'Ci::Pipeline', created_successfully?: false, full_error_messages: 'Fake full error messages' }
        let(:fake_response) { ServiceResponse.error(message: 'Fake error message', payload: fake_pipeline) }
        let(:fake_service) { instance_double "Ci::CreatePipelineService", execute: fake_response }

        before do
          allow(Ci::CreatePipelineService).to receive(:new).and_return(fake_service)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Fake full error messages')
        end
      end

      context 'when on demand scan licensed feature is not available' do
        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Insufficient permissions')
        end
      end
    end
  end
end
