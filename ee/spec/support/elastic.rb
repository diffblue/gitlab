# frozen_string_literal: true

module Elastic
  class TestHelpers
    include ElasticsearchHelpers

    def helper
      @helper ||= Gitlab::Elastic::Helper.default
    end

    def indices
      @indices ||= curator.indices.map { |info| info['index'] } + [helper.migrations_index_name]
    end

    def curator
      @curator ||= ::Gitlab::Search::IndexCurator.new(
        ignore_patterns: [/migrations/], force: true, dry_run: false
      )
    end

    def setup(multi_index: true)
      clear_tracking!
      delete_indices!
      helper.create_empty_index(options: { settings: { number_of_replicas: 0 } })
      helper.create_migrations_index
      ::Elastic::DataMigrationService.mark_all_as_completed!
      helper.create_standalone_indices
      curator.curate! if multi_index
      refresh_elasticsearch_index!
    end

    def teardown
      delete_indices!
      clear_tracking!
    end

    def clear_tracking!
      Elastic::ProcessInitialBookkeepingService.clear_tracking!
      Elastic::ProcessBookkeepingService.clear_tracking!
    end

    def refresh_elasticsearch_index!
      refresh_index!
    end

    def delete_indices!
      indices.each do |index_name|
        helper.delete_index(index_name: index_name)
      end
    end

    def delete_all_data_from_index!
      helper.client.delete_by_query(
        {
          index: indices,
          body: { query: { match_all: {} } },
          slices: 5,
          conflicts: 'proceed'
        }
      )
    end
  end
end

RSpec.configure do |config|
  config.define_derived_metadata do |meta|
    meta[:clean_gitlab_redis_cache] = true if meta[:elastic] || meta[:elastic_delete_by_query] || meta[:elastic_clean]
  end

  # If using the :elastic tag is causing issues, use :elastic_clean instead.
  # :elastic is significantly faster than :elastic_clean and should be used
  # wherever possible.
  config.before(:all, :elastic) do
    helper = Elastic::TestHelpers.new
    helper.setup(multi_index: true)
  end

  config.after(:all, :elastic) do
    helper = Elastic::TestHelpers.new
    helper.teardown
  end

  config.around(:each, :elastic) do |example|
    helper = Elastic::TestHelpers.new
    helper.refresh_elasticsearch_index!

    example.run
  end

  config.around(:each, :elastic_clean) do |example|
    helper = Elastic::TestHelpers.new
    helper.setup(multi_index: false)

    example.run

    helper.teardown
  end

  config.before(:context, :elastic_delete_by_query) do
    Elastic::TestHelpers.new.setup
  end

  config.after(:context, :elastic_delete_by_query) do
    Elastic::TestHelpers.new.teardown
  end

  config.around(:each, :elastic_delete_by_query) do |example|
    helper = Elastic::TestHelpers.new
    helper.refresh_elasticsearch_index!

    example.run

    helper.delete_all_data_from_index!
  end

  config.include ElasticsearchHelpers, :elastic
  config.include ElasticsearchHelpers, :elastic_clean
  config.include ElasticsearchHelpers, :elastic_delete_by_query
end
