# frozen_string_literal: true

module EE
  module Issues
    module BuildService
      extend ::Gitlab::Utils::Override

      def issue_params_from_template
        return {} unless container.feature_available?(:issuable_default_templates)
        return {} unless container.respond_to?(:issues_template)

        if container.issues_template.present? && params.include?(:description)
          { description: container.issues_template + "\n" + params.delete(:description) }
        else
          { description: container.issues_template }
        end
      end

      # Issue params can be built from 3 types of passed params,
      # They take precedence over eachother like this
      # passed params > discussion params > template params
      # The template params are filled in here, and might be overwritten by super
      override :build_issue_params
      def build_issue_params
        issue_params_from_template.merge(super).with_indifferent_access
      end
    end
  end
end
