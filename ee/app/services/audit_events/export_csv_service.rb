# frozen_string_literal: true

module AuditEvents
  class ExportCsvService
    def initialize(params = {})
      @params = params
    end

    def csv_data
      csv_builder.render
    end

    private

    def csv_builder
      @csv_builder ||= CsvBuilders::Stream.new(data, header_to_value_hash)
    end

    def data
      events = AuditEventFinder.new(**finder_params).execute
      Gitlab::Audit::Events::Preloader.new(events)
    end

    def finder_params
      {
        level: Gitlab::Audit::Levels::Instance.new,
        params: @params
      }
    end

    def header_to_value_hash
      {
        'ID' => 'id',
        'Author ID' => 'author_id',
        'Author Name' => 'author_name',
        'Author Email' => -> (event) { event.author.try(:email) },
        'Entity ID' => 'entity_id',
        'Entity Type' => 'entity_type',
        'Entity Path' => 'entity_path',
        'Target ID' => 'target_id',
        'Target Type' => 'target_type',
        'Target Details' => 'target_details',
        'Action' => -> (event) { Audit::Details.humanize(event.details) },
        'IP Address' => 'ip_address',
        'Created At (UTC)' => -> (event) { event.created_at.utc.iso8601 }
      }
    end
  end
end
