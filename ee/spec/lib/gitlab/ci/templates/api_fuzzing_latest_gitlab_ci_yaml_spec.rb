# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'API-Fuzzing.latest.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('API-Fuzzing.latest') }

  specify { expect(template).not_to be_nil }

  describe 'the template file' do
    let(:template_filename) { Rails.root.join("lib/gitlab/ci/templates/" + template.full_name) }
    let(:contents) { File.read(template_filename) }
    let(:production_registry) { '${SECURE_ANALYZERS_PREFIX}/api-fuzzing:${FUZZAPI_VERSION}' }
    let(:staging_registry) { '${SECURE_ANALYZERS_PREFIX}/api-fuzzing-src:${FUZZAPI_VERSION}' }

    # Make sure future changes to the template use the production container registry.
    #
    # The API Fuzzing template is developed against a dev container registry.
    # The registry is switched when releasing new versions. The difference in
    # names between development and production is also quite small making it
    # easy to miss during review.
    it 'uses the production repository' do
      expect(contents.include?(production_registry)).to be true
    end

    it 'doesn\'t use the staging repository' do
      expect(contents.include?(staging_registry)).to be false
    end
  end

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:default_branch) { 'master' }
    let(:pipeline_branch) { default_branch }
    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    context 'when no stages' do
      before do
        stub_ci_pipeline_yaml_file(template.content)
        allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
          allow(worker).to receive(:perform).and_return(true)
        end
        allow(project).to receive(:default_branch).and_return(default_branch)
      end

      context 'when project has no stages' do
        it 'includes no jobs' do
          expect(build_names).to be_empty
        end
      end
    end

    context 'when stages includes fuzz' do
      let(:ci_pipeline_yaml) { "stages: [\"fuzz\"]\n" }

      before do
        stub_ci_pipeline_yaml_file(ci_pipeline_yaml + template.content)

        allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
          allow(worker).to receive(:perform).and_return(true)
        end

        allow(project).to receive(:default_branch).and_return(default_branch)
      end

      context 'when project has no license' do
        before do
          create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
          create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
        end

        it 'includes job to display error' do
          expect(build_names).to match_array(%w[apifuzzer_fuzz])
        end
      end

      context 'when project has Ultimate license' do
        let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

        before do
          allow(License).to receive(:current).and_return(license)
        end

        context 'by default' do
          it 'includes a job' do
            expect(build_names).to match_array(%w[apifuzzer_fuzz])
          end
        end

        context 'when configured with HAR' do
          before do
            create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
            create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
          end

          it 'includes job' do
            expect(build_names).to match_array(%w[apifuzzer_fuzz])
          end
        end

        context 'when configured with OpenAPI' do
          before do
            create(:ci_variable, project: project, key: 'FUZZAPI_OPENAPI', value: 'testing.json')
            create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
          end

          it 'includes job' do
            expect(build_names).to match_array(%w[apifuzzer_fuzz])
          end
        end

        context 'when configured with Postman' do
          before do
            create(:ci_variable, project: project, key: 'FUZZAPI_POSTMAN_COLLECTION', value: 'testing.json')
            create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
          end

          it 'includes job' do
            expect(build_names).to match_array(%w[apifuzzer_fuzz])
          end
        end

        context 'when API_FUZZING_DISABLED=1' do
          before do
            create(:ci_variable, project: project, key: 'API_FUZZING_DISABLED', value: '1')
            create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
            create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
          end

          it 'includes no jobs' do
            expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
          end
        end
      end
    end
  end
end
