# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StartPullMirroringService, feature_category: :source_code_management do
  let(:project) { create(:project, :mirror, :repository) }
  let(:user) { create(:user) }
  let(:import_state) { project.import_state }

  subject { described_class.new(project, user, pause_on_hard_failure: pause_on_hard_failure) }

  shared_examples_for 'retry count did not reset' do
    it 'does not reset import state retry_count' do
      expect { execute }.not_to change { import_state.retry_count }
    end
  end

  shared_examples_for 'pull mirroring has started' do
    shared_examples_for 'force mirror update' do
      it 'enqueues UpdateAllMirrorsWorker' do
        Sidekiq::Testing.fake! do
          expect { execute }
            .to change { UpdateAllMirrorsWorker.jobs.size }
            .by(1)
          expect(execute[:status]).to eq(:success)
        end
      end
    end

    it_behaves_like 'force mirror update'

    shared_examples 'mirrors using interval' do |interval_minutes:|
      context 'when project mirror has been updated in the interval' do
        it 'schedules next execution' do
          freeze_time do
            import_state.update!(last_update_at: (interval_minutes - 1).minutes.ago, last_successful_update_at: 10.minutes.ago)

            expect { execute }
              .to change { import_state.next_execution_timestamp }
              .to(interval_minutes.minutes.since(import_state.last_update_at))
              .and not_change { UpdateAllMirrorsWorker.jobs.size }
          end
        end
      end

      context 'when project mirror has been updated outside of the interval' do
        before do
          import_state.update!(last_update_at: (interval_minutes + 1).minutes.ago, last_successful_update_at: 10.minutes.ago)
        end

        it_behaves_like 'force mirror update'
      end

      context 'when project mirror has been updated in interval but has never been successfully updated' do
        before do
          import_state.update!(last_update_at: (interval_minutes - 1).minutes.ago, last_successful_update_at: nil)
        end

        it_behaves_like 'force mirror update'
      end
    end

    context 'with default interval' do
      it_behaves_like 'mirrors using interval', interval_minutes: 5
    end

    context 'with a custom interval' do
      before do
        Plan.default.actual_limits.update!(pull_mirror_interval_seconds: 2.minutes)
      end

      it_behaves_like 'mirrors using interval', interval_minutes: 2
    end
  end

  shared_examples_for 'pull mirroring has not started' do |status|
    it 'does not start pull mirroring' do
      expect { execute }.to not_change { UpdateAllMirrorsWorker.jobs.size }
      expect(execute[:status]).to eq(status)
    end
  end

  before do
    import_state.update!(next_execution_timestamp: 1.minute.from_now)
  end

  context 'when pause_on_hard_failure is false' do
    let(:pause_on_hard_failure) { false }

    context "when retried more than #{Gitlab::Mirror::MAX_RETRY} times" do
      before do
        import_state.update!(retry_count: Gitlab::Mirror::MAX_RETRY + 1)
      end

      it_behaves_like 'pull mirroring has started'

      it 'resets the import state retry_count' do
        expect { execute }.to change { import_state.retry_count }.to(0)
      end

      context 'when mirror is due to be updated' do
        before do
          import_state.update!(next_execution_timestamp: 1.minute.ago)
        end

        it_behaves_like 'pull mirroring has started'
      end
    end

    context 'when does not reach the max retry limit yet' do
      before do
        import_state.update!(retry_count: Gitlab::Mirror::MAX_RETRY - 1)
      end

      it_behaves_like 'pull mirroring has started'
      it_behaves_like 'retry count did not reset'

      context 'when mirror is due to be updated' do
        before do
          import_state.update!(next_execution_timestamp: 1.minute.ago)
        end

        it_behaves_like 'pull mirroring has not started', :success
      end
    end
  end

  context 'when pause_on_hard_failure is true' do
    let(:pause_on_hard_failure) { true }

    context "when retried more than #{Gitlab::Mirror::MAX_RETRY} times" do
      before do
        import_state.update!(retry_count: Gitlab::Mirror::MAX_RETRY + 1)
      end

      it_behaves_like 'retry count did not reset'
      it_behaves_like 'pull mirroring has not started', :error
    end

    context 'when does not reach the max retry limit yet' do
      before do
        import_state.update!(retry_count: Gitlab::Mirror::MAX_RETRY - 1)
      end

      it_behaves_like 'pull mirroring has started'
      it_behaves_like 'retry count did not reset'

      context 'when mirror is due to be updated' do
        before do
          import_state.update!(next_execution_timestamp: 1.minute.ago)
        end

        it_behaves_like 'pull mirroring has not started', :success
      end
    end
  end

  def execute
    subject.execute
  end
end
