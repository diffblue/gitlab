# frozen_string_literal: true

module EE
  module IssuableActions
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    EE_PERMITTED_KEYS = %i[
      sprint_id
      weight
      health_status
      epic_id
    ].freeze

    private

    override :bulk_update_permitted_keys
    def bulk_update_permitted_keys
      @permitted_keys ||= (super + EE_PERMITTED_KEYS).freeze
    end

    override :set_application_context!
    def set_application_context!
      ::Gitlab::ApplicationContext.push(ai_resource: issuable.try(:to_global_id))
    end
  end
end
