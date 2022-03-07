# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::CancelPendingPipelines do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:prev_pipeline) { create(:ci_pipeline, project: project) }
  let(:new_commit) { create(:commit, project: project) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: new_commit.sha) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  before do
    create(:ci_build, :interruptible, :running, pipeline: prev_pipeline)
    create(:ci_build, :interruptible, :success, pipeline: prev_pipeline)
    create(:ci_build, :created, pipeline: prev_pipeline)

    create(:ci_build, :interruptible, pipeline: pipeline)
  end

  describe '#perform!' do
    subject(:perform) { step.perform! }

    before do
      expect(build_statuses(prev_pipeline)).to contain_exactly('running', 'success', 'created')
      expect(build_statuses(pipeline)).to contain_exactly('pending')
    end

    context 'when auto-cancel is enabled' do
      before do
        project.update!(auto_cancel_pending_pipelines: 'enabled')
      end

      it 'cancels only previous interruptible builds' do
        perform

        expect(build_statuses(prev_pipeline)).to contain_exactly('canceled', 'success', 'canceled')
        expect(build_statuses(pipeline)).to contain_exactly('pending')
      end

      it 'cancels the builds with 2 queries to avoid query timeout' do
        second_query_regex = /WHERE "ci_pipelines"\."id" = \d+ AND \(NOT EXISTS/
        recorder = ActiveRecord::QueryRecorder.new { perform }
        second_query = recorder.occurrences.keys.filter { |occ| occ =~ second_query_regex }

        expect(second_query).to be_one
      end

      context 'when the previous pipeline has a child pipeline' do
        let(:child_pipeline) { create(:ci_pipeline, child_of: prev_pipeline) }

        context 'when the child pipeline has only interruptible running jobs' do
          before do
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
          end

          it 'cancels all child pipeline builds' do
            expect(build_statuses(child_pipeline)).to contain_exactly('running', 'running')

            perform

            expect(build_statuses(child_pipeline)).to contain_exactly('canceled', 'canceled')
          end

          context 'when the child pipeline includes completed interruptible jobs' do
            before do
              create(:ci_build, :interruptible, :failed, pipeline: child_pipeline)
              create(:ci_build, :interruptible, :success, pipeline: child_pipeline)
            end

            it 'cancels all child pipeline builds with a cancelable_status' do
              expect(build_statuses(child_pipeline)).to contain_exactly('running', 'running', 'failed', 'success')

              perform

              expect(build_statuses(child_pipeline)).to contain_exactly('canceled', 'canceled', 'failed', 'success')
            end
          end
        end

        context 'when the child pipeline has started non-interruptible job' do
          before do
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
            # non-iterruptible started
            create(:ci_build, :success, pipeline: child_pipeline)
          end

          it 'does not cancel any child pipeline builds' do
            expect(build_statuses(child_pipeline)).to contain_exactly('running', 'success')

            perform

            expect(build_statuses(child_pipeline)).to contain_exactly('running', 'success')
          end
        end

        context 'when the child pipeline has non-interruptible non-started job' do
          before do
            create(:ci_build, :interruptible, :running, pipeline: child_pipeline)
            # non-iterruptible but non-started
            create(:ci_build, :created, pipeline: child_pipeline)
          end

          it 'cancels all child pipeline builds' do
            expect(build_statuses(child_pipeline)).to contain_exactly('running', 'created')

            perform

            expect(build_statuses(child_pipeline)).to contain_exactly('canceled', 'canceled')
          end
        end
      end

      context 'when the prev pipeline source is webide' do
        let(:prev_pipeline) { create(:ci_pipeline, :webide, project: project) }

        it 'does not cancel builds of the previous pipeline' do
          perform

          expect(build_statuses(prev_pipeline)).to contain_exactly('created', 'running', 'success')
          expect(build_statuses(pipeline)).to contain_exactly('pending')
        end
      end
    end

    context 'when auto-cancel is disabled' do
      before do
        project.update!(auto_cancel_pending_pipelines: 'disabled')
      end

      it 'does not cancel any build' do
        subject

        expect(build_statuses(prev_pipeline)).to contain_exactly('running', 'success', 'created')
        expect(build_statuses(pipeline)).to contain_exactly('pending')
      end
    end
  end

  private

  def build_statuses(pipeline)
    pipeline.builds.pluck(:status)
  end
end
