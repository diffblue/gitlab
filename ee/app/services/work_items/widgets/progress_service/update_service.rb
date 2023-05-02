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

          # In the followup MR the progress will not be updated rather
          # current value will be updated and progress will be just read-only
          # and will be calculated based on start, end, and current values
          # Issue - https://gitlab.com/gitlab-org/incubation-engineering/okr/meta/-/issues/33
          progress.current_value = params[:progress]

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
