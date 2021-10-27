# frozen_string_literal: true

module EE
  module AuditEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    TRUNCATED_FIELDS = {
      entity_path: 5_500,
      target_details: 5_500
    }.freeze

    prepended do
      scope :by_entity, -> (entity_type, entity_id) { by_entity_type(entity_type).by_entity_id(entity_id) }

      before_validation :truncate_fields
    end

    def entity
      lazy_entity
    end

    def entity_path
      super || details[:entity_path]
    end

    def present
      AuditEventPresenter.new(self)
    end

    def target_type
      super || details[:target_type]
    end

    def target_id
      details[:target_id]
    end

    def target_details
      super || details[:target_details]
    end

    def ip_address
      super&.to_s || details[:ip_address]
    end

    def lazy_entity
      BatchLoader.for(entity_id)
        .batch(
          key: entity_type, default_value: ::Gitlab::Audit::NullEntity.new
        ) do |ids, loader, args|
          model = Object.const_get(args[:key], false)
          model.where(id: ids).find_each { |record| loader.call(record.id, record) }
        end
    end

    def stream_to_external_destinations
      return if entity.nil?
      return unless ::Feature.enabled?(:ff_external_audit_events_namespace, entity)
      return unless entity.licensed_feature_available?(:external_audit_events)

      AuditEvents::AuditEventStreamingWorker.perform_async(id)
    end

    def entity_is_group_or_project?
      %w(Group Project).include?(entity_type)
    end

    private

    def truncate_fields
      TRUNCATED_FIELDS.each do |name, limit|
        original = self[name] || self.details[name]
        next unless original

        self[name] = self.details[name] = String(original).truncate(limit)
      end
    end
  end
end
