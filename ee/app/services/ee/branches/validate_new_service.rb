# frozen_string_literal: true

module EE
  module Branches
    module ValidateNewService
      include ::Gitlab::Utils::StrongMemoize
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(branch_name, force: false)
        super_result = super
        return super_result if super_result[:status] == :error

        return super_result if allowed_by_push_rule?(branch_name)

        branch_name_regex = project.push_rule.branch_name_regex
        message = "Cannot create branch. The branch name must match this regular expression: #{branch_name_regex}"

        error(message)
      end

      private

      def push_rule
        return unless project.licensed_feature_available?(:push_rules)

        project.push_rule
      end

      strong_memoize_attr :push_rule

      def allowed_by_push_rule?(branch_name)
        return true if push_rule.nil?

        push_rule.branch_name_allowed?(branch_name)
      end
    end
  end
end
