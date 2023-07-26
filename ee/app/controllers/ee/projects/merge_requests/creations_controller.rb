# frozen_string_literal: true

module EE
  module Projects
    module MergeRequests
      module CreationsController
        extend ActiveSupport::Concern

        prepended do
          before_action :disable_query_limiting, only: [:create]
          before_action :check_for_saml_authorization, only: [:new]
        end

        private

        def get_target_projects
          return super unless ::Feature.enabled?(:hide_unaccessible_saml_branches, source_project)
          return super unless params[:action] == "target_projects"

          filter_out_saml_groups(super)
        end

        def filter_out_saml_groups(projects)
          groups = target_groups(projects)
          return projects unless groups.any?

          filter_groups = saml_groups(groups, current_user)
          return projects unless filter_groups.any?

          projects.not_in_groups(filter_groups)
        end

        def saml_groups(groups, current_user)
          @saml_groups ||= ::Gitlab::Auth::GroupSaml::SsoEnforcer.access_restricted_groups(groups,
            user: current_user)
        end

        def check_for_saml_authorization
          groups = target_groups(get_target_projects)
          return if groups.empty?

          saml_groups(groups, current_user)
        end

        def source_project
          @project
        end

        def target_groups(projects)
          @target_groups ||= projects.filter_map(&:group)
        end

        def disable_query_limiting
          ::Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20801')
        end
      end
    end
  end
end
