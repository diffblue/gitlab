# frozen_string_literal: true

module WorkItems
  module Widgets
    module ProgressService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_in_transaction(params:)
          return delete_progress if work_item.progress.present? && new_type_excludes_widget?

          return unless params.present? && params.key?(:current_value)
          return unless has_permission?(:admin_work_item)

          progress = work_item.progress || work_item.build_progress

          progress.current_value = params[:current_value]
          progress.start_value = params[:start_value] if params.key?(:start_value)
          progress.end_value = params[:end_value] if params.key?(:end_value)

          progress.progress = params[:current_value].nil? ? nil : progress.compute_progress

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
