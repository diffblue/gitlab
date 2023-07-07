# frozen_string_literal: true

module EE
  module AuditEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    TRUNCATED_FIELDS = {
      entity_path: 5_500,
      target_details: 5_500
    }.freeze

    prepended do
      scope :by_entity, -> (entity_type, entity_id) { by_entity_type(entity_type).by_entity_id(entity_id) }

      before_validation :truncate_fields
    end

    attr_writer :entity
    attr_accessor :root_group_entity_id

    def entity
      strong_memoize(:entity) do
        if entity_type == ::Gitlab::Audit::InstanceScope.name
          ::Gitlab::Audit::InstanceScope.new
        else
          lazy_entity
        end
      end
    end

    def root_group_entity
      strong_memoize(:root_group_entity) do
        next ::Group.find_by(id: root_group_entity_id) if root_group_entity_id.present?
        next if entity.nil?

        root_group_entity =
          case entity_type
          when 'Group'
            # Sub group events should be sent to the root ancestor's streaming destinations
            entity.root_ancestor
          when 'Project'
            # Project events should be sent to the root ancestor's streaming destinations
            # Projects without a group root ancestor should be ignored.
            entity.group&.root_ancestor
          end

        self.root_group_entity_id = root_group_entity&.id
        root_group_entity
      end
    end

    def entity_path
      super || details[:entity_path]
    end

    def present
      AuditEventPresenter.new(self)
    end

    def ip_address
      super&.to_s || details[:ip_address]
    end

    def stream_to_external_destinations(use_json: false, event_name: 'audit_operation')
      return unless can_stream_to_external_destination?(event_name)

      perform_params = use_json ? [event_name, nil, streaming_json] : [event_name, id, nil]
      ::AuditEvents::AuditEventStreamingWorker.perform_async(*perform_params)
    end

    def entity_is_group_or_project?
      %w(Group Project).include?(entity_type)
    end

    private

    def lazy_entity
      BatchLoader.for(entity_id)
                 .batch(
                   key: entity_type, default_value: ::Gitlab::Audit::NullEntity.new
                 ) do |ids, loader, args|
        model = Object.const_get(args[:key], false)
        model.where(id: ids).find_each { |record| loader.call(record.id, record) }
      end
    end

    def can_stream_to_external_destination?(event_name)
      return false if entity.nil?

      ::AuditEvents::ExternalDestinationStreamer.new(event_name, self).streamable?
    end

    def truncate_fields
      TRUNCATED_FIELDS.each do |name, limit|
        original = self[name] || self.details[name]
        next unless original

        self[name] = self.details[name] = String(original).truncate(limit)
      end
    end

    def streaming_json
      ::Gitlab::Json.generate(self, methods: [:root_group_entity_id])
    end
  end
end
