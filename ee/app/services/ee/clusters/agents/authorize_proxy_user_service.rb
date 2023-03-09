# frozen_string_literal: true

module EE
  module Clusters
    module Agents
      module AuthorizeProxyUserService
        extend ::Gitlab::Utils::Override

        override :handle_access
        def handle_access(access_as, user_access)
          super || (access_as.key?(:user) && access_as_user(user_access))
        end

        def access_as_user(user_access)
          projects = authorized_projects(user_access)
          groups = authorized_groups(user_access)
          return unless projects.size + groups.size > 0

          response_base.merge(
            access_as: {
              user: {
                # FIXME: N+1 queries on projects and groups
                # see https://gitlab.com/gitlab-org/gitlab/-/issues/393336
                projects: projects.map { |p| { id: p.id, roles: project_roles(p) } },
                groups: groups.map { |g| { id: g.id, roles: group_roles(g) } }
              }
            }
          )
        end

        def project_roles(project)
          user_access_level = current_user.max_member_access_for_project(project.id)
          ::Gitlab::Access.sym_options_with_owner
            .select { |_role, role_access_level| role_access_level <= user_access_level }
            .map(&:first)
        end

        def group_roles(group)
          user_access_level = current_user.max_member_access_for_group(group.id)
          ::Gitlab::Access.sym_options_with_owner
            .select { |_role, role_access_level| role_access_level <= user_access_level }
            .map(&:first)
        end
      end
    end
  end
end
