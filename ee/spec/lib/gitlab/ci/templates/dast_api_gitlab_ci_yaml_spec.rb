# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DAST-API.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST-API') }

  specify { expect(template).not_to be_nil }

  describe 'the template file' do
    let(:template_filename) { Rails.root.join("lib/gitlab/ci/templates/" + template.full_name) }
    let(:contents) { File.read(template_filename) }
    let(:production_registry) { '$SECURE_ANALYZERS_PREFIX/api-fuzzing:$DAST_API_VERSION' }
    let(:staging_registry) { '$SECURE_ANALYZERS_PREFIX/api-fuzzing-src:$DAST_API_VERSION' }

    # Make sure future changes to the template use the production container registry.
    #
    # The DAST API template is developed against a dev container registry.
    # The registry is switched when releasing new versions. The difference in
    # names between development and production is also quite small making it
    # easy to miss during review.
    it 'uses the production repository' do
      expect(contents.include?(production_registry)).to be true
    end

    it "doesn't use the staging repository" do
      expect(contents.include?(staging_registry)).to be false
    end
  end

  describe 'the created pipeline' do
    let(:default_branch) { 'master' }
    let(:pipeline_branch) { default_branch }
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch ) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end

      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when no stages' do
      before do
        stub_ci_pipeline_yaml_file(template.content)
      end

      context 'when project has no stages' do
        it 'includes no jobs' do
          expect(build_names).to be_empty
        end
      end
    end

    context 'when stages includes dast' do
      let(:ci_pipeline_yaml) { "stages: [\"dast\"]\n" }

      before do
        stub_ci_pipeline_yaml_file(ci_pipeline_yaml + template.content)
      end

      context 'when project has no license' do
        before do
          create(:ci_variable, project: project, key: 'DAST_API_HAR', value: 'testing.har')
          create(:ci_variable, project: project, key: 'DAST_API_TARGET_URL', value: 'http://example.com')
        end

        it 'includes job to display error' do
          expect(build_names).to match_array(%w[dast_api])
        end
      end

      context 'when project has Ultimate license' do
        before do
          stub_licensed_features(dast: true)
        end

        context 'by default' do
          it 'includes a job' do
            expect(build_names).to match_array(%w[dast_api])
          end
        end

        context 'when DAST_API_DISABLED=1' do
          before do
            create(:ci_variable, project: project, key: 'DAST_API_DISABLED', value: '1')
            create(:ci_variable, project: project, key: 'DAST_API_HAR', value: 'testing.har')
            create(:ci_variable, project: project, key: 'DAST_API_TARGET_URL', value: 'http://example.com')
          end

          it 'includes no jobs' do
            expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
          end
        end
      end
    end
  end
end
