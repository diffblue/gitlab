# frozen_string_literal: true

module WorkItems
  module Widgets
    class Weight < Base
      delegate :weight, to: :work_item

      def self.quick_action_commands
        [:weight, :clear_weight]
      end

      def self.quick_action_params
        [:weight]
      end
    end
  end
end
