# frozen_string_literal: true

module Epics
  module EpicLinks
    class DestroyService < IssuableLinks::DestroyService
      attr_reader :child_epic, :parent_epic
      private :child_epic, :parent_epic

      def initialize(child_epic, user)
        @child_epic = child_epic
        @parent_epic = child_epic&.parent
        @current_user = user
      end

      private

      def remove_relation
        child_epic.update!({ parent_id: nil, updated_by: current_user })
      end

      def create_notes
        return unless parent_epic

        SystemNoteService.change_epics_relation(parent_epic, child_epic, current_user, 'unrelate_epic')
      end

      def permission_to_remove_relation?
        child_epic.present? &&
          parent_epic.present? &&
          can?(current_user, :admin_epic_relation, parent_epic) &&
          can?(current_user, :admin_epic_relation, child_epic)
      end

      def not_found_message
        'No Epic found for given params'
      end
    end
  end
end
