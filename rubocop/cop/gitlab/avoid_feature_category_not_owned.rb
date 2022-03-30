# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Gitlab
      class AvoidFeatureCategoryNotOwned < RuboCop::Cop::Cop
        include ::RuboCop::CodeReuseHelpers

        MSG = 'Avoid adding new endpoints with `feature_category :not_owned`. See https://docs.gitlab.com/ee/development/feature_categorization'

        def_node_search :feature_category_not_owned?, <<~PATTERN
          (send nil? :feature_category (sym :not_owned) $...)
        PATTERN

        def_node_search :feature_category_not_owned_api?, <<~PATTERN
          (pair (sym :feature_category) (sym :not_owned))
        PATTERN

        def on_send(node)
          return unless file_needs_feature_category?(node)
          return unless setting_not_owned?(node)

          add_offense(node, location: :expression)
        end

        private

        def file_needs_feature_category?(node)
          in_controller?(node) || in_worker?(node) || in_api?(node)
        end

        def setting_not_owned?(node)
          feature_category_not_owned?(node) || feature_category_not_owned_api?(node)
        end
      end
    end
  end
end
