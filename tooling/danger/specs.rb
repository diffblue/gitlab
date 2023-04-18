# frozen_string_literal: true

require_relative 'specs/match_with_array_suggestion'
require_relative 'specs/project_factory_suggestion'

module Tooling
  module Danger
    module Specs
      include ::Tooling::Danger::Suggestor

      SPEC_FILES_REGEX = 'spec/'
      EE_PREFIX = 'ee/'

      RSPEC_TOP_LEVEL_DESCRIBE_REGEX = /^\+.?RSpec\.describe(.+)/.freeze
      FEATURE_CATEGORY_SUGGESTION = <<~SUGGESTION_MARKDOWN
      Consider adding `feature_category: <feature_category_name>` for this example if it is not set already.
      See [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#feature-category-metadata).
      SUGGESTION_MARKDOWN
      FEATURE_CATEGORY_KEYWORD = 'feature_category'

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
        file_lines = project_helper.file_lines(filename)
        changed_lines = helper.changed_lines(filename)

        changed_lines.each_with_index do |changed_line, i|
          next unless changed_line =~ RSPEC_TOP_LEVEL_DESCRIBE_REGEX

          line_number = file_lines.find_index(changed_line.delete_prefix('+'))
          next unless line_number

          # Get the top level RSpec.describe line and the next 5 lines
          lines_to_check = file_lines[line_number, 5]
          # Remove all the lines after the first one that ends in `do`
          last_line_number_of_describe_declaration = lines_to_check.index { |line| line.end_with?(' do') }
          lines_to_check = lines_to_check[0..last_line_number_of_describe_declaration]

          next if lines_to_check.any? { |line| line.include?(FEATURE_CATEGORY_KEYWORD) }

          suggested_line = file_lines[line_number]

          markdown(comment(FEATURE_CATEGORY_SUGGESTION, suggested_line), file: filename, line: line_number.succ)
        end
      end
    end
  end
end
