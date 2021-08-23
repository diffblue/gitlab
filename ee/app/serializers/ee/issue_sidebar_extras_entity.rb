# frozen_string_literal: true

module EE
  module IssueSidebarExtrasEntity
    extend ActiveSupport::Concern

    prepended do
      expose :epic, if: -> (issuable, _) { can_read_epic?(issuable) } do
        expose :epic, merge: true, using: EpicBaseEntity
        expose :epic_issue_id do |issuable|
          issuable.epic_issue&.id
        end
      end
      expose :weight

      def can_read_epic?(issuable)
        can?(request.current_user, :read_epic, issuable.epic)
      end
    end
  end
end
