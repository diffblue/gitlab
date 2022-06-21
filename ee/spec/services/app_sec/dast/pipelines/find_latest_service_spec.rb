# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Pipelines::FindLatestService do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace, owner: user) }
  let_it_be(:project) { create(:project, :repository, namespace: namespace) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  subject { described_class.new(project: project, current_user: user).execute }

  context 'when a pipeline exists' do
    let_it_be(:pipeline) do
      create(
        :ci_pipeline,
        :auto_devops_source,
        project: project,
        ref: project.default_branch,
        sha: project.commit.sha
      )
    end

    context 'when scanner is enabled' do
      context 'with a successful pipeline' do
        let_it_be(:build_dast) { create(:ci_build, :dast, pipeline: pipeline, status: :success) }

        it 'returns the latest pipeline' do
          expect(subject.payload).to eq(latest_pipeline: pipeline)
        end
      end

      context 'with a failed pipeline' do
        let_it_be(:build_dast) { create(:ci_build, :dast, pipeline: pipeline, status: :failed) }

        it 'returns the latest pipeline' do
          expect(subject.payload).to eq(latest_pipeline: pipeline)
        end
      end
    end

    context 'when scanner is disabled' do
      it 'does not return pipeline info' do
        expect(subject.payload).to be_empty
      end
    end
  end

  context 'when on demand scan licensed feature is not available' do
    before do
      stub_licensed_features(security_on_demand_scans: false)
    end

    it_behaves_like 'an error occurred' do
      let(:error_message) { 'Insufficient permissions' }
    end
  end
end
