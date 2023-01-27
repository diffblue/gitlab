# frozen_string_literal: true

module WorkItems
  module Widgets
    class TestReports < Base
      delegate :test_reports, to: :work_item
    end
  end
end
