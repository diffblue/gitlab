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
      controllers = %w[audit_logs]
      super.concat(controllers)
    end
  end
end
