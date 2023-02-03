# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ProcessBookkeepingService, :clean_gitlab_redis_shared_state, :elastic,
feature_category: :global_search do
  let(:ref_class) { ::Gitlab::Elastic::DocumentReference }

  let(:fake_refs) { Array.new(10) { |i| ref_class.new(Issue, i, "issue_#{i}", 'project_1') } }
  let(:issue) { fake_refs.first }
  let(:issue_spec) { issue.serialize }

  describe '.shard_number' do
    it 'returns correct shard number' do
      shard = described_class.shard_number(ref_class.serialize(fake_refs.first))

      expect(shard).to eq(9)
    end
  end

  describe '.track' do
    it 'enqueues a record' do
      described_class.track!(issue)

      shard = described_class.shard_number(issue_spec)

      spec, score = described_class.queued_items[shard].first

      expect(spec).to eq(issue_spec)
      expect(score).to eq(1.0)
    end

    it 'enqueues a set of unique records' do
      described_class.track!(*fake_refs)

      expect(described_class.queue_size).to eq(fake_refs.size)
      expect(described_class.queued_items.keys).to contain_exactly(0, 1, 3, 4, 6, 8, 9, 10, 13)
    end

    it 'orders items based on when they were added and moves them to the back of the queue if they were added again' do
      shard_number = 9
      item1_in_shard = ref_class.new(Issue, 0, 'issue_0', 'project_1')
      item2_in_shard = ref_class.new(Issue, 8, 'issue_8', 'project_1')

      described_class.track!(item1_in_shard)
      described_class.track!(item2_in_shard)

      expect(described_class.queued_items[shard_number][0]).to eq([item1_in_shard.serialize, 1.0])
      expect(described_class.queued_items[shard_number][1]).to eq([item2_in_shard.serialize, 2.0])

      described_class.track!(item1_in_shard)

      expect(described_class.queued_items[shard_number][0]).to eq([item2_in_shard.serialize, 2.0])
      expect(described_class.queued_items[shard_number][1]).to eq([item1_in_shard.serialize, 3.0])
    end

    it 'enqueues 10 identical records as 1 entry' do
      described_class.track!(*([issue] * 10))

      expect(described_class.queue_size).to eq(1)
    end

    it 'deduplicates across multiple inserts' do
      10.times { described_class.track!(issue) }

      expect(described_class.queue_size).to eq(1)
    end
  end

  describe '.queue_size' do
    it 'reports the queue size' do
      expect(described_class.queue_size).to eq(0)

      described_class.track!(*fake_refs)

      expect(described_class.queue_size).to eq(fake_refs.size)
    end
  end

  describe '.queued_items' do
    it 'reports queued items' do
      expect(described_class.queued_items).to be_empty

      described_class.track!(*fake_refs.take(3))

      expect(described_class.queued_items).to eq(
        4 => [["Issue 1 issue_1 project_1", 1.0]],
        6 => [["Issue 2 issue_2 project_1", 1.0]],
        9 => [["Issue 0 issue_0 project_1", 1.0]]
      )
    end
  end

  describe '.clear_tracking!' do
    it 'removes all entries from the queue' do
      described_class.track!(*fake_refs)

      expect(described_class.queue_size).to eq(fake_refs.size)

      described_class.clear_tracking!

      expect(described_class.queue_size).to eq(0)
    end
  end

  describe '.maintain_indexed_associations' do
    let(:project) { create(:project) }

    it 'calls track! for each associated object' do
      issue_1 = create(:issue, project: project)
      issue_2 = create(:issue, project: project)
      merge_request1 = create(:merge_request, source_project: project, target_project: project)

      expect(described_class).to receive(:track!).with(issue_1, issue_2).ordered
      expect(described_class).to receive(:track!).with(merge_request1).ordered

      described_class.maintain_indexed_associations(project, %w[issues merge_requests])
    end

    it 'correctly scopes associated note objects to not include system notes' do
      note_searchable = create(:note, :on_issue, project: project)
      create(:note, :on_issue, :system, project: project)

      expect(described_class).to receive(:track!).with(note_searchable)

      described_class.maintain_indexed_associations(project, ['notes'])
    end
  end

  describe '#execute' do
    context 'limit is less than refs count' do
      before do
        stub_const('Elastic::ProcessBookkeepingService::SHARD_LIMIT', 2)
        stub_const('Elastic::ProcessBookkeepingService::SHARDS_NUMBER', 2)
      end

      it 'processes only up to limit' do
        described_class.track!(*fake_refs)

        expect(described_class.queue_size).to eq(fake_refs.size)
        allow_processing(*fake_refs)

        expect { described_class.new.execute }.to change(described_class, :queue_size).by(-4)
      end

      context 'limited to one shard' do
        let(:shard_number) { 1 }

        it 'only processes specified shard' do
          described_class.track!(*fake_refs)

          expect(described_class.queue_size).to eq(fake_refs.size)
          allow_processing(*fake_refs)

          refs_in_shard = described_class.queued_items[shard_number]
          expect { described_class.new.execute(shards: [shard_number]) }.to change(described_class, :queue_size)
                                                                        .by(-refs_in_shard.count)
        end
      end
    end

    it 'submits a batch of documents' do
      described_class.track!(*fake_refs)

      expect(described_class.queue_size).to eq(fake_refs.size)
      expect_processing(*fake_refs)

      expect { described_class.new.execute }.to change(described_class, :queue_size).by(-fake_refs.count)
    end

    it 'returns the number of documents processed' do
      described_class.track!(*fake_refs)

      expect_processing(*fake_refs)

      expect(described_class.new.execute).to eq(fake_refs.count)
    end

    it 'returns 0 without writing to the index when there are no documents' do
      expect(::Gitlab::Elastic::BulkIndexer).not_to receive(:new)

      expect(described_class.new.execute).to eq(0)
    end

    it 'retries failed documents' do
      described_class.track!(*fake_refs)
      failed = fake_refs[0]

      expect(described_class.queue_size).to eq(10)
      expect_processing(*fake_refs, failures: [failed])

      expect { described_class.new.execute }.to change(described_class, :queue_size).by(-fake_refs.count + 1)

      shard = described_class.shard_number(failed.serialize)
      serialized = described_class.queued_items[shard].first[0]

      expect(ref_class.deserialize(serialized)).to eq(failed)
    end

    it 'discards malformed documents' do
      described_class.track!('Bad')

      expect(described_class.queue_size).to eq(1)
      expect_next_instance_of(::Gitlab::Elastic::BulkIndexer) do |indexer|
        expect(indexer).not_to receive(:process)
      end

      expect { described_class.new.execute }.to change(described_class, :queue_size).by(-1)
    end

    it 'fails, preserving documents, when processing fails with an exception' do
      described_class.track!(issue)

      expect(described_class.queue_size).to eq(1)
      expect_next_instance_of(::Gitlab::Elastic::BulkIndexer) do |indexer|
        expect(indexer).to receive(:process).with(issue) { raise 'Bad' }
      end

      expect { described_class.new.execute }.to raise_error('Bad')
      expect(described_class.queue_size).to eq(1)
    end

    context 'logging' do
      let(:logger_double) { instance_double(Gitlab::Elasticsearch::Logger) }

      before do
        allow(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
      end

      it 'logs the time it takes to flush the bulk indexer' do
        described_class.track!(*fake_refs)
        expect_processing(*fake_refs)

        expect(logger_double).to receive(:info).with(
          class: described_class.name,
          message: 'bulk_indexer_flushed',
          search_flushing_duration_s: an_instance_of(Float),
          search_indexed_bytes_per_second: an_instance_of(Integer)
        )

        described_class.new.execute
      end

      it 'logs model information and indexing duration about each successful indexing' do
        described_class.track!(*fake_refs)
        expect_processing(*fake_refs)

        expect(logger_double).to receive(:info).with(
          class: described_class.name,
          message: 'indexing_done',
          model_class: "Issue",
          model_id: an_instance_of(String),
          es_id: an_instance_of(String),
          es_parent: "project_1",
          search_indexing_duration_s: an_instance_of(Float),
          search_indexing_flushing_duration_s: an_instance_of(Float)
        ).exactly(fake_refs.size).times

        described_class.new.execute
      end

      it 'does not log about failed indexing' do
        described_class.track!(*fake_refs)

        failed = fake_refs[0]
        expect_processing(*fake_refs, failures: [failed])

        expect(logger_double).not_to receive(:info).with(
          class: described_class.name,
          message: 'indexing_done',
          model_class: "Issue",
          model_id: failed.db_id,
          es_id: failed.es_id,
          es_parent: "project_1",
          search_indexing_duration_s: an_instance_of(Float),
          search_indexing_flushing_duration_s: an_instance_of(Float)
        )

        expect(logger_double).to receive(:info).with(
          class: described_class.name,
          message: 'indexing_done',
          model_class: "Issue",
          model_id: an_instance_of(String),
          es_id: an_instance_of(String),
          es_parent: "project_1",
          search_indexing_duration_s: an_instance_of(Float),
          search_indexing_flushing_duration_s: an_instance_of(Float)
        ).exactly(fake_refs.size - 1).times

        described_class.new.execute
      end

      it 'increments the custom indexing sli apdex' do
        described_class.track!(*fake_refs)
        expect_processing(*fake_refs)

        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_bytes_per_second_apdex).with(
          throughput: a_kind_of(Numeric)
        ).once

        described_class.new.execute
      end

      it 'does not increment the custom indexing sli apdex for failed indexing' do
        described_class.track!(*fake_refs)

        failed = fake_refs[0]
        expect_processing(*fake_refs, failures: [failed])

        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_bytes_per_second_apdex).with(
          throughput: a_kind_of(Numeric)
        ).once

        described_class.new.execute
      end
    end

    context 'N+1 queries' do
      it 'does not have N+1 queries for projects' do
        projects = create_list(:project, 2)

        described_class.track!(*projects)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { described_class.new.execute }

        projects += create_list(:project, 3)

        described_class.track!(*projects)

        expect { described_class.new.execute }.not_to exceed_all_query_limit(control)
      end

      it 'does not have N+1 queries for notes' do
        # Gitaly N+1 calls when processing notes on commits
        # https://gitlab.com/gitlab-org/gitlab/-/issues/327086 . Even though
        # this block is in the spec there is still an N+1 to fix in the actual
        # code.
        Gitlab::GitalyClient.allow_n_plus_1_calls do
          notes = []

          2.times do
            notes << create(:note)
            notes << create(:discussion_note_on_merge_request)
            notes << create(:note_on_merge_request)
            notes << create(:note_on_commit)
            notes << create(:diff_note_on_merge_request)
          end

          described_class.track!(*notes)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { described_class.new.execute }

          3.times do
            notes << create(:note)
            notes << create(:discussion_note_on_merge_request)
            notes << create(:note_on_merge_request)
            notes << create(:note_on_commit)
            notes << create(:diff_note_on_merge_request)
          end

          described_class.track!(*notes)

          expect { described_class.new.execute }.not_to exceed_all_query_limit(control)
        end
      end

      it 'does not have N+1 queries for issues' do
        issues = create_list(:issue, 2)

        described_class.track!(*issues)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { described_class.new.execute }

        issues += create_list(:issue, 3)

        described_class.track!(*issues)

        expect { described_class.new.execute }.not_to exceed_all_query_limit(control)
      end

      it 'does not have N+1 queries for merge_requests' do
        merge_requests = create_list(:merge_request, 2)

        described_class.track!(*merge_requests)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { described_class.new.execute }

        merge_requests += create_list(:merge_request, 3)

        described_class.track!(*merge_requests)

        expect { described_class.new.execute }.not_to exceed_all_query_limit(control)
      end

      it 'does not have N+1 queries for users' do
        users = create_list(:user, 2)

        described_class.track!(*users)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { described_class.new.execute }

        users += create_list(:user, 3)

        described_class.track!(*users)

        expect { described_class.new.execute }.not_to exceed_all_query_limit(control)
      end

      context 'when the user is a member of a project in a namespace with a parent group' do
        let_it_be(:parent_group) { create(:group) }
        let_it_be(:group) { create(:group, parent: parent_group) }
        let_it_be(:project) { create(:project, group: group) }

        it 'does not have N+1 queries for users' do
          users = create_list(:user, 2)
          users.each { |user| project.add_developer(user) }

          described_class.track!(*users)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { described_class.new.execute }

          new_users = create_list(:user, 3)
          new_users.each { |user| project.add_developer(user) }

          users += new_users

          described_class.track!(*users)

          expect { described_class.new.execute }.not_to exceed_all_query_limit(control)
        end
      end
    end

    def expect_processing(*refs, failures: [])
      expect_next_instance_of(::Gitlab::Elastic::BulkIndexer) do |indexer|
        refs.each { |ref| expect(indexer).to receive(:process).with(ref).and_return(10) }

        expect(indexer).to receive(:flush) { failures }
      end
    end

    def allow_processing(*refs, failures: [])
      expect_next_instance_of(::Gitlab::Elastic::BulkIndexer) do |indexer|
        refs.each { |ref| allow(indexer).to receive(:process).with(anything).and_return(10) }

        expect(indexer).to receive(:flush) { failures }
      end
    end
  end
end
