# frozen_string_literal: true

module EE
  module Projects
    module CreateService
      extend ::Gitlab::Utils::Override

      attr_reader :security_policy_target_project_id

      override :initialize
      def initialize(user, params)
        super

        @security_policy_target_project_id = @params.delete(:security_policy_target_project_id)
      end

      override :execute
      def execute
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
          create_security_policy_configuration if security_policy_target_project?
        end

        create_predefined_push_rule
      end

      def security_policy_target_project?
        security_policy_target_project_id && ::Feature.enabled?(:security_orchestration_policies_configuration, project)
      end

      def create_security_policy_configuration
        if (security_policy_target_project = ::Project.find(security_policy_target_project_id))
          ::Security::Orchestration::AssignService
            .new(security_policy_target_project, current_user, policy_project_id: project.id)
            .execute
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def create_predefined_push_rule
        return unless project.feature_available?(:push_rules)

        predefined_push_rule = PushRule.find_by(is_sample: true)

        if group_push_rule_available?
          create_push_rule_from_group
        elsif predefined_push_rule
          log_info(predefined_push_rule)
          push_rule = predefined_push_rule.dup.tap { |gh| gh.is_sample = false }
          project.push_rule = push_rule
          project.project_setting.update(push_rule: push_rule)
        end
      end

      def group_push_rule_available?
        return false unless project.group

        !!project.group.predefined_push_rule
      end

      def create_push_rule_from_group
        push_rule_attributes = project.group.predefined_push_rule.attributes.except("id")
        project.create_push_rule(push_rule_attributes.merge(is_sample: false))
        project.project_setting.update(push_rule: project.push_rule)
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
        ::AuditEventService.new(
          current_user,
          project,
          action: :create
        ).for_project.security_event
      end
    end
  end
end
