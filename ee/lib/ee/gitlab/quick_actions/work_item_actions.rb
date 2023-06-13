# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module WorkItemActions
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override
        include ::Gitlab::QuickActions::Dsl

        private

        override :promote_to_map
        def promote_to_map
          super.merge(key_result: 'Objective')
        end
      end
    end
  end
end
