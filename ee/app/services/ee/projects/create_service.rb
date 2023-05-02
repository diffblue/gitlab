# frozen_string_literal: true

module EE
  module Projects
    module CreateService
      extend ::Gitlab::Utils::Override

      AUDIT_EVENT_TYPE = 'project_created'
      AUDIT_EVENT_MESSAGE = 'Project created'

      attr_reader :security_policy_target_project_id, :security_policy_target_namespace_id

      override :initialize
      def initialize(user, params)
        super

        @security_policy_target_project_id = @params.delete(:security_policy_target_project_id)
        @security_policy_target_namespace_id = @params.delete(:security_policy_target_namespace_id)
      end

      override :execute
      def execute
        if create_from_template?
          return ::Projects::CreateFromTemplateService.new(current_user, params).execute
        end

        limit = params.delete(:repository_size_limit)
        mirror = ::Gitlab::Utils.to_boolean(params.delete(:mirror))
        mirror_user_id = current_user.id if mirror
        mirror_trigger_builds = params.delete(:mirror_trigger_builds)
        ci_cd_only = ::Gitlab::Utils.to_boolean(params.delete(:ci_cd_only))
        group_with_project_templates_id = params.delete(:group_with_project_templates_id) if params[:template_name].blank? && params[:template_project_id].blank?

        project = super do |project|
          # Repository size limit comes as MB from the view
          project.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

          if mirror && can?(current_user, :admin_mirror, project)
            project.mirror = mirror unless mirror.nil?
            project.mirror_trigger_builds = mirror_trigger_builds unless mirror_trigger_builds.nil?
            project.mirror_user_id = mirror_user_id
          end

          validate_namespace_used_with_template(project, group_with_project_templates_id)
        end

        if project&.persisted?
          setup_ci_cd_project if ci_cd_only

          log_geo_event(project)
          log_audit_event(project)
        end

        project
      end

      private

      def log_geo_event(project)
        ::Geo::RepositoryCreatedEventStore.new(project).create!
      end

      override :after_create_actions
      def after_create_actions
        super do
          create_security_policy_configuration_if_exists
        end

        create_predefined_push_rule if ::Feature.disabled?(:inherited_push_rule_for_project, project)
        set_default_compliance_framework

        sync_group_scan_result_policies if project.group
      end

      def create_security_policy_configuration_if_exists
        security_policy_target = find_security_policy_target
        return if security_policy_target.blank?

        ::Security::Orchestration::AssignService
            .new(container: security_policy_target, current_user: current_user, params: { policy_project_id: project.id })
            .execute
      end

      def find_security_policy_target
        if security_policy_target_project_id.present?
          ::Project.find_by_id(security_policy_target_project_id)
        elsif security_policy_target_namespace_id.present?
          ::Namespace.find_by_id(security_policy_target_namespace_id)
        end
      end

      def sync_group_scan_result_policies
        configurations = project.group.all_security_orchestration_policy_configurations

        configurations.each do |configuration|
          ::Security::ProcessScanResultPolicyWorker.perform_async(project.id, configuration.id)
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def create_predefined_push_rule
        return unless project.feature_available?(:push_rules)
        return unless predefined_push_rule.present?

        log_info(predefined_push_rule)
        push_rule = predefined_push_rule.dup.tap { |predefined_rule| predefined_rule.is_sample = false }
        project.push_rule = push_rule
        project.project_setting.update(push_rule: push_rule)
      end

      def predefined_push_rule
        if project.group
          project.group.predefined_push_rule
        else
          PushRule.global
        end
      end

      def set_default_compliance_framework
        return unless project.group

        return unless project.licensed_feature_available?(:custom_compliance_frameworks)

        default_compliance_framework_id = project.root_namespace.namespace_settings.default_compliance_framework_id

        return if default_compliance_framework_id.blank?

        ::ComplianceManagement::UpdateDefaultFrameworkWorker.perform_async(
          current_user.id,
          project.id,
          default_compliance_framework_id
        )
      end

      # When using a project template from a Group, the new project can only be created
      # under the template owner's group or subgroups
      def validate_namespace_used_with_template(project, group_with_project_templates_id)
        return unless project.group

        subgroup_with_templates_id = group_with_project_templates_id || params[:group_with_project_templates_id]
        return if subgroup_with_templates_id.blank?

        templates_owner = ::Group.find(subgroup_with_templates_id).parent

        unless templates_owner.self_and_descendants.exists?(id: project.namespace_id)
          project.errors.add(:namespace, _("is not a descendant of the Group owning the template"))
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def setup_ci_cd_project
        return unless ::License.feature_available?(:ci_cd_projects)

        ::CiCd::SetupProject.new(project, current_user).execute
      end

      def log_audit_event(project)
        audit_context = {
          name: AUDIT_EVENT_TYPE,
          author: current_user,
          scope: project,
          target: project,
          message: AUDIT_EVENT_MESSAGE,
          target_details: project.full_path
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
