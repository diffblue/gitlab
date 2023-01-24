# frozen_string_literal: true

module WorkItems
  module Widgets
    module Filters
      class RequirementLegacy
        def self.filter(relation, params)
          legacy_iids = params.dig(:requirement_legacy_widget, :legacy_iids)

          return relation unless legacy_iids

          relation.for_requirement_iids(legacy_iids)
        end
      end
    end
  end
end
