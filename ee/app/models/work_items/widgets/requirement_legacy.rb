# frozen_string_literal: true

module WorkItems
  module Widgets
    class RequirementLegacy < Base
      def legacy_iid
        work_item.requirement&.iid
      end
    end
  end
end
