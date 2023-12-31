# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'
require 'did_you_mean'

require_relative '../../feature_categories'

module RuboCop
  module Cop
    module RSpec
      # Ensures that feature categories in specs are valid.
      #
      # @example
      #
      #   # bad
      #   RSpec.describe 'foo', feature_category: :invalid do
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :not_owned do
      #   end
      #
      #   # good
      #
      #   RSpec.describe 'foo', feature_category: :wiki do
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :tooling do
      #   end
      #
      class InvalidFeatureCategory < RuboCop::Cop::RSpec::Base
        MSG = 'Please use a valid feature category. %{msg_suggestion}' \
              'See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.'

        MSG_DID_YOU_MEAN = 'Did you mean `:%{suggestion}`? '

        MSG_SYMBOL = 'Please use a symbol as value.'

        # @!method feature_category?(node)
        def_node_matcher :feature_category_value, <<~PATTERN
          (block
            (send #rspec? {#ExampleGroups.all #Examples.all} ...
              (hash <(pair (sym :feature_category) $_) ...>)
            )
            ...
          )
        PATTERN

        def on_block(node)
          value_node = feature_category_value(node)
          return unless value_node

          unless value_node.sym_type?
            add_offense(value_node, message: MSG_SYMBOL)
            return
          end

          return if valid_feature_category?(value_node)

          message = format(MSG, msg_suggestion: suggestion_message(value_node))
          add_offense(value_node, message: message)
        end

        def external_dependency_checksum
          FeatureCategories.config_checksum
        end

        private

        def suggestion_message(value_node)
          spell = DidYouMean::SpellChecker.new(dictionary: FeatureCategories.available_with_custom)

          suggestions = spell.correct(value_node.value)
          return if suggestions.none?

          format(MSG_DID_YOU_MEAN, suggestion: suggestions.first)
        end

        def valid_feature_category?(node)
          FeatureCategories.available_with_custom.include?(node.value.to_s)
        end
      end
    end
  end
end
