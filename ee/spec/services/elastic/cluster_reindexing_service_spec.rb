# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ClusterReindexingService, :elastic, :clean_gitlab_redis_shared_state do
  subject(:cluster_reindexing_service) { described_class.new }

  let(:helper) { Gitlab::Elastic::Helper.new }

  before do
    allow(Gitlab::Elastic::Helper).to receive(:default).and_return(helper)
  end

  context 'state: initial' do
    let(:task) { create(:elastic_reindexing_task, state: :initial) }

    it 'aborts if the main index does not use aliases' do
      allow(helper).to receive(:alias_exists?).and_return(false)

      expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('initial').to('failure')
      expect(task.reload.error_message).to match(/use aliases/)
    end

    it 'aborts if there are pending ES migrations' do
      allow(Elastic::DataMigrationService).to receive(:pending_migrations?).and_return(true)

      expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('initial').to('failure')
      expect(task.reload.error_message).to match(/unapplied advanced search migrations/)
    end

    it 'errors when there is not enough space' do
      allow(helper).to receive(:index_size_bytes).and_return(100.megabytes)
      allow(helper).to receive(:cluster_free_size_bytes).and_return(30.megabytes)

      expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('initial').to('failure')
      expect(task.reload.error_message).to match(/storage available/)
    end

    it 'pauses elasticsearch indexing' do
      expect(Gitlab::CurrentSettings.elasticsearch_pause_indexing).to eq(false)

      expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('initial').to('indexing_paused')

      expect(Gitlab::CurrentSettings.elasticsearch_pause_indexing).to eq(true)
    end
  end

  context 'state: indexing_paused' do
    it 'creates subtasks and slices' do
      task = create(:elastic_reindexing_task, state: :indexing_paused)

      allow(helper).to receive(:create_empty_index).and_return('new_index_name' => 'new_index')
      allow(helper).to receive(:create_standalone_indices).and_return('new_issues_name' => 'new_issues')
      allow(helper).to receive(:reindex).with(from: anything, to: 'new_index_name', slice: anything, max_slice: anything).and_return('task_id_1')
      allow(helper).to receive(:reindex).with(from: anything, to: 'new_issues_name', slice: anything, max_slice: anything).and_return('task_id_2')
      allow(helper).to receive(:get_settings).with(index_name: 'new_index').and_return({ 'number_of_shards' => '10' })
      allow(helper).to receive(:get_settings).with(index_name: 'new_issues').and_return({ 'number_of_shards' => '3' })

      expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('indexing_paused').to('reindexing')

      subtasks = task.subtasks.order(:index_name_to)
      expect(subtasks.count).to eq(2)

      slice_1 = subtasks.first.slices.first
      expect(subtasks.first.index_name_to).to eq('new_index_name')
      expect(subtasks.first.slices.count).to eq(20)
      expect(slice_1.elastic_max_slice).to eq(20)
      expect(slice_1.elastic_task).to eq('task_id_1')
      expect(slice_1.elastic_slice).to eq(0)

      slice_2 = subtasks.last.slices.last
      expect(subtasks.last.index_name_to).to eq('new_issues_name')
      expect(subtasks.last.slices.count).to eq(6)
      expect(slice_2.elastic_max_slice).to eq(6)
      expect(slice_2.elastic_task).to eq('task_id_2')
      expect(slice_2.elastic_slice).to eq(5)
    end

    context 'when targets are provided' do
      let(:task) { create(:elastic_reindexing_task, state: :indexing_paused, targets: targets) }

      before do
        allow(helper).to receive(:create_standalone_indices)
                          .with(with_alias: false, options: { settings: described_class::INITIAL_INDEX_OPTIONS }, target_classes: task.target_classes)
                          .and_return('new_issues_name' => 'new_issues')
      end

      context 'targets set to issue and repository' do
        let(:targets) { %w[Issue Repository] }

        it 'creates multiple indices' do
          expect(helper).to receive(:create_empty_index).and_return('new_index_name' => 'new_index')
          is_expected.to receive(:launch_subtasks).with('new_index_name' => 'new_index', 'new_issues_name' => 'new_issues')

          cluster_reindexing_service.execute
        end
      end

      context 'targets do not include repository' do
        let(:targets) { %w[Issue] }

        it 'does not create the main index' do
          expect(helper).not_to receive(:create_empty_index)
          is_expected.to receive(:launch_subtasks).with('new_issues_name' => 'new_issues')

          cluster_reindexing_service.execute
        end
      end
    end
  end

  context 'state: reindexing' do
    let!(:task) { create(:elastic_reindexing_task, state: :reindexing, max_slices_running: 1) }
    let!(:subtask) { create(:elastic_reindexing_subtask, elastic_reindexing_task: task, documents_count: 10) }
    let!(:slices) { [slice_1, slice_2, slice_3] }
    let(:slice_1) { create(:elastic_reindexing_slice, elastic_reindexing_subtask: subtask, elastic_max_slice: 3, elastic_slice: 0) }
    let(:slice_2) { create(:elastic_reindexing_slice, elastic_reindexing_subtask: subtask, elastic_max_slice: 3, elastic_slice: 1) }
    let(:slice_3) { create(:elastic_reindexing_slice, elastic_reindexing_subtask: subtask, elastic_max_slice: 3, elastic_slice: 2) }
    let(:refresh_interval) { nil }
    let(:expected_default_settings) do
      {
        refresh_interval: refresh_interval,
        number_of_replicas: Elastic::IndexSetting[subtask.alias_name].number_of_replicas,
        translog: { durability: 'request' }
      }
    end

    before do
      allow(helper).to receive(:task_status).and_return({ 'completed' => true, 'response' => { 'total' => 20, 'created' => 20, 'updated' => 0, 'deleted' => 0 } })
      allow(helper).to receive(:refresh_index).and_return(true)
      allow(helper).to receive(:reindex).and_return('task_1', 'task_2', 'task_3', 'task_4', 'task_5', 'task_6')
    end

    context 'errors are raised' do
      context 'documents count' do
        before do
          allow(helper).to receive(:documents_count).with(index_name: anything).and_return(subtask.reload.documents_count * 2)
        end

        it 'errors if documents count is different' do
          # kick off reindexing for each slice
          slices.count.times do
            cluster_reindexing_service.execute
          end

          expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('reindexing').to('failure')
          expect(task.reload.error_message).to match(/count is different/)
        end
      end

      context 'reindexing slice failed' do
        before do
          cluster_reindexing_service.execute # run once to kick off reindexing for slices

          allow(helper).to receive(:task_status).and_return({ 'completed' => true, 'error' => { 'type' => 'search_phase_execution_exception' } })
        end

        context 'when retry limit is reached on a slice' do
          it 'errors and changes task state from reindexing to failed' do
            10.times do
              cluster_reindexing_service.execute
            end

            expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('reindexing').to('failure')
            expect(task.reload.error_message).to match(/has failed with/)
          end
        end

        context 'before retry limit reached' do
          it 'increases retry_attempt and reindexes the slice again' do
            expect { cluster_reindexing_service.execute }.to change { slices.first.reload.retry_attempt }.by(1).and change { slices.first.reload.elastic_task }
            expect(task.reload.state).to eq('reindexing')
            # once for initial reindex, once for retry
            expect(helper).to have_received(:reindex).with(from: subtask.index_name_from, to: subtask.index_name_to, max_slice: 3, slice: 0).twice
          end
        end
      end

      context 'slice totals do not match' do
        before do
          cluster_reindexing_service.execute # run once to kick off reindexing for slices

          allow(helper).to receive(:task_status).and_return({ 'completed' => true, 'response' => { 'total' => 20, 'created' => 10, 'updated' => 0, 'deleted' => 0 } })
        end

        context 'when retry limit is reached on a slice' do
          it 'errors and changes task state from reindexing to failed' do
            10.times do
              cluster_reindexing_service.execute
            end

            expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('reindexing').to('failure')
            expect(task.reload.error_message).to match(/total: \d+ is not equal/)
          end
        end

        context 'before retry limit reached' do
          it 'increases retry_attempt and reindexes the slice again' do
            expect { cluster_reindexing_service.execute }.to change { slices.first.reload.retry_attempt }.by(1).and change { slices.first.reload.elastic_task }
            expect(task.reload.state).to eq('reindexing')
            # once for initial reindex, once for retry
            expect(helper).to have_received(:reindex).with(from: subtask.index_name_from, to: subtask.index_name_to, max_slice: 3, slice: 0).twice
          end
        end
      end

      it 'errors if task is not found' do
        cluster_reindexing_service.execute # run once to kick off reindexing for slices
        allow(helper).to receive(:task_status).and_raise(Elasticsearch::Transport::Transport::Errors::NotFound)

        expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('reindexing').to('failure')
        expect(task.reload.error_message).to match(/couldn't load task status/i)
      end
    end

    context 'slice batching' do
      it 'kicks off the next set of slices if the current slice is finished', :aggregate_failures do
        expect { cluster_reindexing_service.execute }.to change { slice_1.reload.elastic_task }
        expect(helper).to have_received(:reindex).with(from: subtask.index_name_from, to: subtask.index_name_to, max_slice: 3, slice: 0)

        expect { cluster_reindexing_service.execute }.to change { slice_2.reload.elastic_task }
        expect(helper).to have_received(:reindex).with(from: subtask.index_name_from, to: subtask.index_name_to, max_slice: 3, slice: 1)

        expect { cluster_reindexing_service.execute }.to change { slice_3.reload.elastic_task }
        expect(helper).to have_received(:reindex).with(from: subtask.index_name_from, to: subtask.index_name_to, max_slice: 3, slice: 2)
      end
    end

    context 'task finishes correctly' do
      using RSpec::Parameterized::TableSyntax

      where(:refresh_interval, :current_settings) do
        nil | {}
        '60s' | { refresh_interval: '60s' }
      end

      with_them do
        before do
          allow(helper).to receive(:documents_count).with(index_name: subtask.index_name_to).and_return(subtask.reload.documents_count)
          allow(helper).to receive(:get_settings).with(index_name: subtask.index_name_from).and_return(current_settings.with_indifferent_access)
        end

        it 'launches all state steps' do
          expect(helper).to receive(:update_settings).with(index_name: subtask.index_name_to, settings: expected_default_settings)
          expect(helper).to receive(:switch_alias).with(to: subtask.index_name_to, from: subtask.index_name_from, alias_name: subtask.alias_name)
          expect(Gitlab::CurrentSettings).to receive(:update!).with(elasticsearch_pause_indexing: false)

          # kick off reindexing for each slice
          slices.count.times do
            cluster_reindexing_service.execute
          end

          expect { cluster_reindexing_service.execute }.to change { task.reload.state }.from('reindexing').to('success')
          expect(task.reload.delete_original_index_at).to be_within(1.minute).of(described_class::DELETE_ORIGINAL_INDEX_AFTER.from_now)
        end
      end
    end
  end
end
