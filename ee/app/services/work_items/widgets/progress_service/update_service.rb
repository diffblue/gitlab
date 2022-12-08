# frozen_string_literal: true

module WorkItems
  module Widgets
    module ProgressService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_in_transaction(params:)
          return unless params.present? && params.key?(:progress)
          return unless has_permission?(:admin_work_item)

          progress = work_item.progress || work_item.build_progress
          progress.progress = params[:progress]

          raise WidgetError, progress.errors.full_messages.join(', ') unless progress.save

          work_item.touch
        end
      end
    end
  end
end
