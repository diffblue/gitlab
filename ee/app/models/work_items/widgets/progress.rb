# frozen_string_literal: true

module WorkItems
  module Widgets
    class Progress < Base
      def progress
        work_item&.progress&.progress
      end
    end
  end
end
