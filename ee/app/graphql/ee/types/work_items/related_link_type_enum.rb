# frozen_string_literal: true

module EE
  module Types
    module WorkItems
      module RelatedLinkTypeEnum
        extend ActiveSupport::Concern

        prepended do
          value 'BLOCKED_BY', 'Blocked by type.', value: 'is_blocked_by'
          value 'BLOCKS', 'Blocks type.', value: 'blocks'
        end
      end
    end
  end
end
