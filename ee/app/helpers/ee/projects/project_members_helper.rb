# frozen_string_literal: true

module EE
  module Projects
    module ProjectMembersHelper
      def project_member_header_subtext(project)
        if project.group &&
          ::Namespaces::FreeUserCap.notification_or_enforcement_enabled?(project.root_ancestor) &&
          can?(current_user, :admin_group_member, project.root_ancestor)
          super + member_header_manage_namespace_members_text(project.root_ancestor)
        else
          super
        end
      end
    end
  end
end
