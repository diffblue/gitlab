# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::AnalyzeCiJobFailureService, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new(user, job, {}) }

  describe '#perform', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

    shared_context 'with prerequisites' do
      before do
        stub_feature_flags(ai_build_failure_cause: flags_enabled)
        stub_feature_flags(openai_experimentation: flags_enabled)
        stub_licensed_features(ai_analyze_ci_job_failure: licensed_feature_avalible)

        if has_permission
          allow(job).to receive(:debug_mode?).and_return(false)
          group.add_developer(user)
        end

        allow(Gitlab::Llm::StageCheck).to receive(:available?).and_return(stage_avalible)
      end
    end

    context 'when all conditions are satisfied' do
      where(:flags_enabled, :licensed_feature_avalible, :has_permission, :stage_avalible) do
        true | true | true | true
      end

      with_them do
        include_context 'with ai features enabled for group'
        include_context 'with prerequisites'

        it 'is successful' do
          expect(subject.execute).to be_success
        end
      end
    end

    context 'when at least one condition is not satisfied' do
      where(:flags_enabled, :licensed_feature_avalible, :has_permission, :stage_avalible) do
        # Only enumerate a single value being false since testing
        # every edge case dosn't bring much value in this case
        false | true  | true   | true
        true  | false | true   | true
        true  | true  | false  | true
        true  | true  | true   | false
      end

      with_them do
        include_context 'with prerequisites'

        it 'returns an error' do
          expect(subject.execute).to be_error
        end
      end
    end
  end
end
