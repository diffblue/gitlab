# frozen_string_literal: true

module EE
  module ResourceStateEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      belongs_to :epic

      scope :aliased_for_timebox_report, -> do
        select("'state' AS event_type", "id", "created_at", "state AS value", "NULL AS action", "issue_id")
      end
    end

    class_methods do
      def issuable_attrs
        %i[epic].freeze + super
      end
    end

    override :issuable
    def issuable
      epic || super
    end
  end
end
