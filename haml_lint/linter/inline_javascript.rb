# frozen_string_literal: true

module HamlLint
  class Linter
    class InlineJavaScript < Linter
      include ::HamlLint::LinterRegistry

      def visit_filter(node)
        return unless node.filter_type == 'javascript'

        record_lint(node, 'Inline JavaScript is discouraged (https://docs.gitlab.com/ee/development/gotchas.html#do-not-use-inline-javascript-in-views)')
      end

      def visit_tag(node)
        return unless node.tag_name == 'script'

        record_lint(node, 'Inline JavaScript is discouraged (https://docs.gitlab.com/ee/development/gotchas.html#do-not-use-inline-javascript-in-views)')
      end
    end
  end
end
