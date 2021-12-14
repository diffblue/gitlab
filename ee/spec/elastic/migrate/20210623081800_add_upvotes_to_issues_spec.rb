# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210623081800_add_upvotes_to_issues.rb')

RSpec.describe AddUpvotesToIssues, :elastic, :sidekiq_inline do
  let(:version) { 20210623081800 }
  let(:migration) { described_class.new(version) }
  let(:issues) { create_list(:issue, 3) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    # ensure issues are indexed
    issues

    ensure_elasticsearch_index!
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.throttle_delay).to eq(3.minutes)
    end
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'when migration is already completed' do
      it 'does not modify data' do
        expect(::Elastic::ProcessInitialBookkeepingService).not_to receive(:track!)

        subject
      end
    end

    context 'migration process' do
      before do
        remove_upvotes_from_issues(issues)
      end

      it 'updates all issue documents' do
        # track calls are batched in groups of 100
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).once do |*tracked_refs|
          expect(tracked_refs.count).to eq(3)
        end

        subject
      end

      it 'only updates issue documents missing upvotes', :aggregate_failures do
        issue = issues.first
        add_upvotes_for_issues(issues[1..])

        expected = [Gitlab::Elastic::DocumentReference.new(Issue, issue.id, issue.es_id, issue.es_parent)]
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).with(*expected).once

        subject
      end

      it 'processes in batches', :aggregate_failures do
        stub_const("#{described_class}::QUERY_BATCH_SIZE", 2)
        stub_const("#{described_class}::UPDATE_BATCH_SIZE", 1)

        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).exactly(3).times.and_call_original

        # cannot use subject in spec because it is memoized
        migration.migrate

        ensure_elasticsearch_index!

        migration.migrate
      end
    end
  end

  describe '.completed?' do
    context 'when documents are missing upvotes' do
      before do
        remove_upvotes_from_issues(issues)
      end

      specify { expect(migration).not_to be_completed }
    end

    context 'when no documents are missing upvotes' do
      specify { expect(migration).to be_completed }
    end
  end

  private

  def add_upvotes_for_issues(issues)
    script =  {
      source: "ctx._source['upvotes'] = params.upvotes;",
      lang: "painless",
      params: {
        upvotes: 0
      }
    }

    update_by_query(issues, script)
  end

  def remove_upvotes_from_issues(issues)
    script =  {
      source: "ctx._source.remove('upvotes')"
    }

    update_by_query(issues, script)
  end

  def update_by_query(issues, script)
    issue_ids = issues.map { |i| i.id }

    client = Issue.__elasticsearch__.client
    client.update_by_query({
      index: Issue.__elasticsearch__.index_name,
      wait_for_completion: true, # run synchronously
      refresh: true, # make operation visible to search
      body: {
        script: script,
        query: {
          bool: {
            must: [
              {
                terms: {
                  id: issue_ids
                }
              }
            ]
          }
        }
      }
    })
  end
end
