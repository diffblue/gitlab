# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :continuous_integration do
  include AfterNextHelpers
  include RepoHelpers

  subject(:execute) { service.execute(:push) }

  let_it_be(:project) { create(:project, :repository, path: 'website') }
  let_it_be(:user) { project.first_owner }
  let_it_be(:compliance_group) { create(:group, :private) }
  let_it_be(:compliance_project) { create(:project, :repository, namespace: compliance_group) }
  let_it_be(:framework) { create(:compliance_framework, namespace_id: compliance_group.id, pipeline_configuration_full_path: ".compliance-gitlab-ci.yml@#{compliance_project.full_path}") }
  let!(:framework_project_setting) { create(:compliance_framework_project_setting, project: project, framework_id: framework.id) }
  let!(:ref_sha) { compliance_project.commit('HEAD').sha }
  let(:compliance_config) do
    <<~EOY
    ---
    compliance_build:
      stage: build
      script:
        - echo 'hello from compliance build'
    compliance_test:
      stage: test
      script:
        - echo 'hello from compliance test'
    EOY
  end

  let(:service) { described_class.new(project, user, { ref: 'master' }) }

  before do
    stub_licensed_features(evaluate_group_level_compliance_pipeline: true)
  end

  around(:all) do |example|
    create_and_delete_files(compliance_project, { '.compliance-gitlab-ci.yml' => compliance_config }) do
      example.run
    end
  end

  context 'when user has access to compliance project' do
    before do
      compliance_project.add_maintainer(project.first_owner)
    end

    it 'responds with success' do
      is_expected.to be_success
    end

    it 'persists pipeline' do
      expect(execute.payload).to be_persisted
    end

    it 'sets the correct source' do
      expect(execute.payload.config_source).to eq("compliance_source")
    end

    it 'persists jobs' do
      expect { execute }.to change(Ci::Build, :count).from(0).to(2)
    end

    it do
      expect(execute.payload.processables.map(&:name)).to contain_exactly('compliance_build', 'compliance_test')
    end
  end

  context 'when user does not have access to compliance project' do
    it 'includes access denied error' do
      expect(execute.payload.yaml_errors).to eq "Project `#{compliance_project.full_path}` not found or access denied! Make sure any includes in the pipeline configuration are correctly defined."
    end

    it 'does not persist jobs' do
      expect { execute }.not_to change(Ci::Build, :count).from(0)
    end
  end
end
