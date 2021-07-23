# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secure-Binaries.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Secure-Binaries') }

  specify { expect(template).not_to be_nil }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch ) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)

      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end

      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    shared_examples 'an offline image download job' do
      let(:build) { pipeline.builds.find_by(name: build_name) }

      it 'creates the job' do
        expect(build_names).to include(build_name)
      end

      it 'sets SECURE_BINARIES_ANALYZER_VERSION to the correct version' do
        expect(build.variables.to_hash).to include('SECURE_BINARIES_ANALYZER_VERSION' => String(version))
      end
    end

    describe 'dast' do
      let_it_be(:build_name) { 'dast' }
      let_it_be(:version) { 2 }

      it_behaves_like 'an offline image download job'
    end

    describe 'dast-runner-validation' do
      let_it_be(:build_name) { 'dast-runner-validation' }
      let_it_be(:version) { 1 }

      it_behaves_like 'an offline image download job' do
        it 'sets SECURE_BINARIES_IMAGE explicitly' do
          image = 'registry.gitlab.com/security-products/${CI_JOB_NAME}:${SECURE_BINARIES_ANALYZER_VERSION}'

          expect(build.variables.to_hash).to include('SECURE_BINARIES_IMAGE' => image)
        end
      end
    end
  end
end
