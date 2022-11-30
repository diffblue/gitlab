# frozen_string_literal: true

module WorkItems
  module Widgets
    class HealthStatus < Base
      delegate :health_status, to: :work_item
    end
  end
end
