# frozen_string_literal: true

module WorkItems
  module Widgets
    class Progress < Base
      def progress
        work_item&.progress&.progress
      end

      def updated_at
        work_item&.progress&.updated_at
      end
    end
  end
end
