# frozen_string_literal: true

module EE
  module NavHelper
    extend ::Gitlab::Utils::Override

    override :page_has_markdown?
    def page_has_markdown?
      super || current_path?('epics#show')
    end

    override :admin_monitoring_nav_links
    def admin_monitoring_nav_links
      controllers = %w(audit_logs)
      super.concat(controllers)
    end

    private

    # This is a temporary measure until we support all other existing sidebars:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/391500
    # https://gitlab.com/gitlab-org/gitlab/-/issues/391501
    # https://gitlab.com/gitlab-org/gitlab/-/issues/391502
    override :super_sidebar_supported?
    def super_sidebar_supported?
      @nav == 'security' || super # rubocop:disable Rails/HelperInstanceVariable
    end
  end
end
