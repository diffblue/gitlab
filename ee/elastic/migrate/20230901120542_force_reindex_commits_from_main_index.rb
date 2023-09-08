# frozen_string_literal: true

class ForceReindexCommitsFromMainIndex < Elastic::Migration
  include Elastic::MigrationHelper

  batched!
  throttle_delay 3.minutes
  batch_size 200
  retry_on_failure

  ELASTIC_TIMEOUT = '5m'
  SCHEMA_VERSION = 23_09

  def migrate
    if completed?
      log 'Migration Completed', total_remaining: 0
      return
    end

    batch_of_rids_to_reindex.each do |rid|
      ElasticCommitIndexerWorker.perform_in(rand(throttle_delay), rid, false, force: true)
      update_schema_version(rid)
    end
  end

  def completed?
    total_remaining = remaining_documents_count
    set_migration_state(documents_remaining: total_remaining)
    log('Checking if migration is finished', total_remaining: total_remaining)
    total_remaining == 0
  end

  private

  def batch_of_rids_to_reindex
    results = client.search(index: index_name, body: {
      size: 0, query: query, aggs: { rids: { terms: { size: batch_size, field: 'commit.rid' } } }
    })
    rids_hist = results.dig('aggregations', 'rids', 'buckets') || []
    rids_hist.pluck('key') # rubocop: disable CodeReuse/ActiveRecord
  end

  def update_schema_version(rid)
    q = query
    q[:bool][:filter] << { term: { 'commit.rid' => rid } }
    client.update_by_query(index: index_name, routing: "project_#{rid}",
      wait_for_completion: true, timeout: ELASTIC_TIMEOUT, conflicts: 'proceed',
      body: { query: q, script: { source: "ctx._source.schema_version = #{SCHEMA_VERSION}" } }
    )
  end

  def remaining_documents_count
    helper.refresh_index(index_name: index_name)
    client.count(index: index_name, body: { query: query })['count']
  end

  def query
    { bool: { filter: [{ term: { type: 'commit' } }], must_not: { exists: { field: 'schema_version' } } } }
  end

  def index_name
    Elastic::Latest::Config.index_name
  end
end
