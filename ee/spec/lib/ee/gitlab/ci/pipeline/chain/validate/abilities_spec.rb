# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::Abilities do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build_stubbed(:ci_pipeline, project: project)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command
      .new(project: project, current_user: user, origin_ref: ref)
  end

  let(:step) { described_class.new(pipeline, command) }
  let(:ref) { 'master' }

  describe '#perform!' do
    before do
      project.add_developer(user)
    end

    context 'when triggering builds for project mirrors is disabled' do
      it 'returns an error' do
        allow(command)
          .to receive(:allow_mirror_update)
          .and_return(true)

        allow(project)
          .to receive(:mirror_trigger_builds?)
          .and_return(false)

        step.perform!

        expect(pipeline.errors.to_a)
          .to include('Pipeline is disabled for mirror updates')
      end
    end

    context 'when user is security_policy_bot and CI/CD disabled' do
      let_it_be(:user) { create(:user, user_type: :security_policy_bot) }

      before do
        project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
      end

      context 'when pipeline source is security_orchestration_policy' do
        let_it_be(:pipeline) { build_stubbed(:ci_pipeline, project: project, source: 'security_orchestration_policy') }

        it 'does not add errors to pipeline' do
          step.perform!

          expect(pipeline.errors).to be_empty
        end
      end

      context 'when pipeline source is not security_orchestration_policy' do
        it 'adds errors to pipeline' do
          step.perform!

          expect(pipeline.errors.to_a).to include('Pipelines are disabled!')
        end
      end
    end
  end
end
