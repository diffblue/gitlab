# frozen_string_literal: true

module ComplianceManagement
  module ComplianceFramework
    module GroupSettingsHelper
      def show_compliance_frameworks?(group)
        can?(current_user, :admin_compliance_framework, group)
      end

      def compliance_frameworks_list_data(group)
        {}.tap do |data|
          data[:empty_state_svg_path] = image_path('illustrations/welcome/ee_trial.svg')
          data[:group_path] = group.root_ancestor.full_path
          data[:can_add_edit] = group.subgroup? ? "false" : "true"
          data[:pipeline_configuration_full_path_enabled] = pipeline_configuration_full_path_enabled?(group).to_s
          data[:pipeline_configuration_enabled] =
            group.licensed_feature_available?(:compliance_pipeline_configuration).to_s
          data[:graphql_field_name] = ComplianceManagement::Framework.name
        end
      end

      private

      def pipeline_configuration_full_path_enabled?(group)
        can?(current_user, :admin_compliance_pipeline_configuration, group).to_s
      end
    end
  end
end
