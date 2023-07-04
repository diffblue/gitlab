# frozen_string_literal: true

module EE
  module WorkItems
    module ResourceLinkEvent
      extend ActiveSupport::Concern

      prepended do
        belongs_to :user

        scope :aliased_for_timebox_report, -> do
          select("'link' AS event_type", "id", "created_at", "child_work_item_id as value", "action", "issue_id")
        end
      end
    end
  end
end
