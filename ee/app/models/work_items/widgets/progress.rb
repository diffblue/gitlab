# frozen_string_literal: true

module WorkItems
  module Widgets
    class Progress < Base
      delegate :progress, :updated_at, :current_value, :start_value, :end_value, to: :progress_instance, allow_nil: true

      def progress_instance
        work_item&.progress
      end
    end
  end
end
