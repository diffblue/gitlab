# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::AnalyzeCiJobFailureService, feature_category: :continuous_integration do
  subject { described_class.new(user, job, {}) }

  describe '#perform', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

    shared_examples 'flags disabled' do
      context 'with feature flag disabled' do
        before do
          stub_feature_flags(ai_build_failure_cause: false)
          stub_feature_flags(openai_experimentation: false)
        end

        it 'returns an error' do
          expect(subject.execute).to be_error
        end
      end
    end

    context 'without licensed feature avalible' do
      context 'without permission' do
        it 'returns an error' do
          expect(subject.execute).to be_error
        end

        it_behaves_like 'flags disabled'
      end

      context 'with permissons' do
        before do
          allow(job).to receive(:debug_mode?).and_return(false)
          project.add_maintainer(user)
        end

        it 'returns an error' do
          expect(subject.execute).to be_error
        end

        it_behaves_like 'flags disabled'
      end
    end

    context 'with licensed feature avalible' do
      before do
        stub_licensed_features(ai_analyze_ci_job_failure: true)
      end

      context 'without permission' do
        it 'returns an error' do
          expect(subject.execute).to be_error
        end

        it_behaves_like 'flags disabled'
      end

      context 'with read build trace permission' do
        before do
          allow(job).to receive(:debug_mode?).and_return(false)
          project.add_maintainer(user)
        end

        it 'responds successfully' do
          response = subject.execute

          expect(response).to be_success
        end

        it_behaves_like 'flags disabled'
      end
    end
  end
end
