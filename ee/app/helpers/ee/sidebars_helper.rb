# frozen_string_literal: true

module EE
  module SidebarsHelper
    extend ::Gitlab::Utils::Override

    override :project_sidebar_context_data
    def project_sidebar_context_data(project, user, current_ref, **args)
      super.merge({
        show_promotions: show_promotions?(user),
        show_discover_project_security: show_discover_project_security?(project),
        learn_gitlab_enabled: Onboarding::LearnGitlab.new(user).onboarding_and_available?(project.namespace)
      })
    end

    override :group_sidebar_context_data
    def group_sidebar_context_data(group, user)
      super.merge(
        show_promotions: show_promotions?(user),
        show_discover_group_security: show_discover_group_security?(group)
      )
    end

    override :super_sidebar_nav_panel
    def super_sidebar_nav_panel(nav: nil, project: nil, user: nil, group: nil, current_ref: nil, ref_type: nil)
      if nav == 'security'
        context = ::Sidebars::Context.new(current_user: user, container: nil,
          route_is_active: method(:active_nav_link?))
        ::Sidebars::Security::Panel.new(context)
      else
        super
      end
    end
  end
end
