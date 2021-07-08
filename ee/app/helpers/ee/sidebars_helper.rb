# frozen_string_literal: true

module EE
  module SidebarsHelper
    extend ::Gitlab::Utils::Override

    override :project_sidebar_context_data
    def project_sidebar_context_data(project, user, current_ref)
      super.merge({
        show_promotions: show_promotions?(user),
        show_discover_project_security: show_discover_project_security?(project)
      })
    end

    override :group_sidebar_context_data
    def group_sidebar_context_data(group, user)
      super.merge(
        show_discover_group_security: show_discover_group_security?(group)
      )
    end
  end
end
