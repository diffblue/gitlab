# frozen_string_literal: true

module AuditEvents
  class BulkInsertService
    BATCH_SIZE = 100

    # service_collection - An array of audit event services that must respond to:
    # - enabled?
    # - attributes (Hash of AuditEvent attributes)
    # - write_log
    def initialize(service_collection)
      @service_collection = service_collection
    end

    def execute
      collection = @service_collection.select(&:enabled?)

      return if collection.empty?

      collection.in_groups_of(BATCH_SIZE, false) do |services|
        ::Gitlab::Database.main.bulk_insert(::AuditEvent.table_name, services.map(&:attributes)) # rubocop:disable Gitlab/BulkInsert

        services.each(&:log_security_event_to_file)
      end
    end
  end
end
