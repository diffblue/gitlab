# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secure-Binaries.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST-Runner-Validation') }

  specify { expect(template).not_to be_nil }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)

      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end

      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    describe 'validation' do
      let_it_be(:build_name) { 'validation' }

      it 'creates a validation job' do
        expect(build_names).to include(build_name)
      end

      it 'sets DAST_RUNNER_VALIDATION_VERSION to the correct version' do
        build = pipeline.builds.find_by(name: build_name)

        expect(build.variables.to_hash).to include('DAST_RUNNER_VALIDATION_VERSION' => '1')
      end
    end
  end
end
