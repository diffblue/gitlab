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

        def check_for_saml_authorization
          groups = get_target_projects.filter_map(&:group)
          return if groups.empty?

          saml_groups(groups, current_user)
        end

        def saml_groups(groups, current_user)
          @saml_groups ||= ::Gitlab::Auth::GroupSaml::SsoEnforcer.access_restricted_groups(groups,
            user: current_user)
        end

        def disable_query_limiting
          ::Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20801')
        end
      end
    end
  end
end
