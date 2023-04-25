# frozen_string_literal: true

module EE
  module Issuable
    module CommonSystemNotesService
      extend ::Gitlab::Utils::Override
      attr_reader :issuable

      override :execute
      def execute(issuable, old_labels: [], old_milestone: nil, is_update: true)
        super

        ApplicationRecord.no_touching do
          handle_weight_change
          handle_iteration_change

          if is_update
            handle_date_change_note
            handle_health_status_change
          end
        end
      end

      private

      def handle_date_change_note
        if issuable.previous_changes.include?('start_date')
          ::SystemNoteService.change_epic_date_note(issuable, current_user, 'start date', issuable['start_date'])
        end

        if issuable.previous_changes.include?('end_date')
          ::SystemNoteService.change_epic_date_note(issuable, current_user, 'finish date', issuable['end_date'])
        end
      end

      def handle_iteration_change
        return unless issuable.previous_changes.include?('sprint_id')

        ::ResourceEvents::ChangeIterationService.new(issuable, current_user, old_iteration_id: issuable.sprint_id_before_last_save).execute
      end

      def handle_weight_change
        return unless issuable.previous_changes.include?('weight')

        ::ResourceEvents::ChangeWeightService.new(issuable, current_user).execute
      end

      def handle_health_status_change
        return unless issuable.previous_changes.include?('health_status')

        ::SystemNoteService.change_health_status_note(issuable, issuable.project, current_user,
          issuable.health_status_before_last_save)
      end
    end
  end
end
