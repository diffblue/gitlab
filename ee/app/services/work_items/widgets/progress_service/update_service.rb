# frozen_string_literal: true

module WorkItems
  module Widgets
    module ProgressService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_in_transaction(params:)
          return delete_progress if work_item.progress.present? && new_type_excludes_widget?

          return unless params.present? && params.key?(:progress)
          return unless has_permission?(:admin_work_item)

          progress = work_item.progress || work_item.build_progress
          progress.progress = params[:progress]

          raise WidgetError, progress.errors.full_messages.join(', ') unless progress.save

          create_notes if progress.saved_change_to_attribute?(:progress)

          work_item.touch
        end

        private

        def delete_progress
          work_item.progress.destroy!

          create_notes

          work_item.touch
        end

        def create_notes
          ::SystemNoteService.change_progress_note(work_item, current_user)
        end
      end
    end
  end
end
