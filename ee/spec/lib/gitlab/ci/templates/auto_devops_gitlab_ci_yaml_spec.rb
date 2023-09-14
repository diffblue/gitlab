# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Auto-DevOps.gitlab-ci.yml', feature_category: :auto_devops do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps') }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :auto_devops, :custom_repo, files: { 'README.md' => '' }) }

    let(:default_branch) { project.default_branch_or_main }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: default_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_application_setting(default_branch_name: default_branch)
      stub_ci_pipeline_yaml_file(template.content)

      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
    end

    context 'when project has ultimate license' do
      let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      it 'does not include the license_scanning job' do
        expect(build_names).not_to include('license_scanning')
      end

      context 'when LICENSE_MANAGEMENT_DISABLED="false"' do
        before do
          create(:ci_variable, project: project, key: 'LICENSE_MANAGEMENT_DISABLED', value: 'false')
        end

        it 'includes the license_scanning job' do
          expect(build_names).to include('license_scanning')
        end
      end
    end
  end
end
