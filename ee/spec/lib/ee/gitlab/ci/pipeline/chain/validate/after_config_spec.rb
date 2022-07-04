# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::AfterConfig do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_pipeline, project: project)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command
      .new(project: project, current_user: user, origin_ref: ref, save_incompleted: true)
  end

  let(:step) { described_class.new(pipeline, command) }
  let(:ref) { 'master' }

  describe '#perform!' do
    before do
      project.add_developer(user)
    end

    describe 'credit card requirement', :saas do
      context 'when user does not have credit card for pipelines in project' do
        before do
          allow(user)
            .to receive(:has_required_credit_card_to_run_pipelines?)
            .with(project)
            .and_return(false)
        end

        it 'breaks the chain with an error' do
          step.perform!

          expect(step.break?).to be_truthy
          expect(pipeline.errors.to_a)
            .to include('Credit card required to be on file in order to create a pipeline')
          expect(pipeline.failure_reason).to eq('user_not_verified')
          expect(pipeline).to be_persisted # when passing a failure reason the pipeline is persisted
        end

        it 'logs the event' do
          allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
          allow(Gitlab::AppLogger).to receive(:info)

          expect(Gitlab::AppLogger).to receive(:info).with(
            message: 'Credit card required to be on file in order to create a pipeline',
            project_path: project.full_path,
            user_id: user.id,
            plan: 'free')

          step.perform!
        end
      end

      context 'when user has credit card for pipelines in project' do
        before do
          allow(user)
            .to receive(:has_required_credit_card_to_run_pipelines?)
            .with(project)
            .and_return(true)
        end

        it 'succeeds the step' do
          step.perform!

          expect(step.break?).to be_falsey
          expect(pipeline.errors).to be_empty
        end
      end
    end
  end
end
