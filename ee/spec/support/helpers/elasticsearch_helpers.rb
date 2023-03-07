# frozen_string_literal: true

module ElasticsearchHelpers
  def assert_named_queries(*expected_names)
    es_host = Gitlab::CurrentSettings.elasticsearch_url.first
    search_uri =
      Addressable::Template.new("#{es_host}/{index}/_search{?params*}")

    ensure_names_present = lambda do |req|
      payload = Gitlab::Json.parse(req.body)
      query = payload["query"]

      return false unless query.present?

      inspector = ElasticQueryNameInspector.new

      inspector.inspect(query)
      inspector.has_named_query?(*expected_names)
    rescue ::JSON::ParserError
      false
    end

    a_named_query = a_request(:post, search_uri).with(&ensure_names_present)
    message = "Expected a query with the following names: #{expected_names.inspect}"
    expect(a_named_query).to have_been_made.at_least_once, message
  end

  def ensure_elasticsearch_index!
    # Ensure that any enqueued updates are processed
    Elastic::ProcessBookkeepingService.new.execute
    Elastic::ProcessInitialBookkeepingService.new.execute

    # Make any documents added to the index visible
    refresh_index!
  end

  def refresh_index!
    es_helper.refresh_index
    es_helper.refresh_index(index_name: es_helper.migrations_index_name)
  end

  def set_elasticsearch_migration_to(name_or_version, including: true)
    version = if name_or_version.is_a?(Numeric)
                name_or_version
              else
                Elastic::DataMigrationService.find_by_name!(name_or_version).version
              end

    Elastic::DataMigrationService.migrations.each do |migration|
      return_value = if including
                       migration.version <= version
                     else
                       migration.version < version
                     end

      allow(Elastic::DataMigrationService).to receive(:migration_has_finished?)
        .with(migration.name_for_key.to_sym)
        .and_return(return_value)
    end
  end

  def warm_elasticsearch_migrations_cache!
    ::Elastic::DataMigrationService.migrations.each do |migration|
      ::Elastic::DataMigrationService.migration_has_finished?(migration.name.underscore.to_sym)
    end
  end

  def es_helper
    Gitlab::Elastic::Helper.default
  end

  def elasticsearch_hit_ids(result)
    result.response['hits']['hits'].map(&:_source).map(&:id)
  end
end
