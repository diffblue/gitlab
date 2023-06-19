# frozen_string_literal: true

module EE
  module Clusters
    module Agents
      module AuthorizeProxyUserService
        extend ::Gitlab::Utils::Override

        override :handle_access
        def handle_access(access_as)
          super || (access_as.key?('user') && access_as_user)
        end

        private

        def access_as_user
          unless agent.project.licensed_feature_available?(:cluster_agents_user_impersonation)
            return forbidden('User impersonation requires EEP license.')
          end

          if authorizations.empty?
            return forbidden('You must be a member of `projects` or `groups` under the `user_access` keyword.')
          end

          payload = response_base.merge(
            access_as: {
              user: {
                projects: projects_payload,
                groups: groups_payload
              }
            }
          )

          success(payload: payload)
        end

        def projects_payload
          project_authorizations.map do |authorization|
            { id: authorization.project_id, roles: roles(authorization.access_level) }
          end
        end

        def groups_payload
          group_authorizations.map do |authorization|
            { id: authorization.group_id, roles: roles(authorization.access_level) }
          end
        end

        def roles(access_level)
          ::Gitlab::Access.sym_options_with_owner
            .select { |_role, role_access_level| role_access_level <= access_level }
            .map(&:first)
        end

        def project_authorizations
          @project_authorizations ||= authorizations.select do |authorization|
            authorization.is_a?(::Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization)
          end
        end

        def group_authorizations
          @group_authorizations ||= authorizations.select do |authorization|
            authorization.is_a?(::Clusters::Agents::Authorizations::UserAccess::GroupAuthorization)
          end
        end
      end
    end
  end
end
