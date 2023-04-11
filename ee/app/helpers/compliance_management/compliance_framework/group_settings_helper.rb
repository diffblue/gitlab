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
          data[:group_edit_path] = edit_group_path(group, anchor: 'js-compliance-frameworks-settings')
          data[:group_path] = group.root_ancestor.full_path
          data[:add_framework_path] = new_group_compliance_framework_path(group) unless group.subgroup?
          data[:edit_framework_path] = edit_group_compliance_framework_path(group, :id) unless group.subgroup?
          data[:pipeline_configuration_full_path_enabled] = pipeline_configuration_full_path_enabled?(group).to_s
          data[:graphql_field_name] = ComplianceManagement::Framework.name
        end
      end

      def compliance_frameworks_form_data(group, framework_id = nil)
        {
          framework_id: framework_id,
          group_path: group.root_ancestor.full_path,
          group_edit_path: edit_group_path(group, anchor: 'js-compliance-frameworks-settings'),
          graphql_field_name: ComplianceManagement::Framework.name,
          pipeline_configuration_full_path_enabled: pipeline_configuration_full_path_enabled?(group).to_s
        }
      end

      private

      def pipeline_configuration_full_path_enabled?(group)
        can?(current_user, :admin_compliance_pipeline_configuration, group)
      end
    end
  end
end
