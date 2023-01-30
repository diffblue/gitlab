# frozen_string_literal: true

module WorkItems
  module Widgets
    class HealthStatus < Base
      delegate :health_status, to: :work_item

      def self.quick_action_commands
        [:health_status, :clear_health_status]
      end

      def self.quick_action_params
        [:health_status]
      end
    end
  end
end
