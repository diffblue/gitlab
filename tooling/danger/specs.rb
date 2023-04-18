# frozen_string_literal: true

require_relative 'specs/match_with_array_suggestion'
require_relative 'specs/project_factory_suggestion'
require_relative 'specs/feature_category_suggestion'

module Tooling
  module Danger
    module Specs
      include ::Tooling::Danger::Suggestor

      SPEC_FILES_REGEX = 'spec/'
      EE_PREFIX = 'ee/'

      def changed_specs_files(ee: :include)
        changed_files = helper.all_changed_files
        folder_prefix =
          case ee
          when :include
            "(#{EE_PREFIX})?"
          when :only
            EE_PREFIX
          when :exclude
            nil
          end

        changed_files.grep(%r{\A#{folder_prefix}#{SPEC_FILES_REGEX}})
      end

      def add_suggestions_for_match_with_array(filename)
        MatchWithArraySuggestion.new(filename, context: self).suggest
      end

      def add_suggestions_for_project_factory_usage(filename)
        ProjectFactorySuggestion.new(filename, context: self).suggest
      end

      def add_suggestions_for_feature_category(filename)
        FeatureCategorySuggestion.new(filename, context: self).suggest
      end
    end
  end
end
