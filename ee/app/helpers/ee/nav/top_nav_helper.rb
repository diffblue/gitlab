# frozen_string_literal: true

module EE
  module Nav
    module TopNavHelper
      extend ::Gitlab::Utils::Override

      private

      override :build_view_model
      def build_view_model(builder:, project:, group:)
        super

        if dashboard_nav_link?(:environments)
          builder.add_primary_menu_item(
            id: 'environments',
            title: 'Environments',
            icon: 'environment',
            data: { qa_selector: 'environment_link' },
            href: operations_environments_path
          )
        end

        if dashboard_nav_link?(:operations)
          builder.add_primary_menu_item(
            id: 'operations',
            title: 'Operations',
            icon: 'cloud-gear',
            data: { qa_selector: 'operations_link' },
            href: operations_path
          )
        end

        if dashboard_nav_link?(:security)
          builder.add_primary_menu_item(
            id: 'security',
            title: 'Security',
            icon: 'shield',
            data: { qa_selector: 'security_link' },
            href: security_dashboard_path
          )
        end

        if ::Gitlab::Geo.secondary? && ::Gitlab::Geo.primary_node_configured?
          builder.add_secondary_menu_item(
            id: 'geo',
            title: _('Go to primary node'),
            icon: 'location-dot',
            href: ::Gitlab::Geo.primary_node.url
          )
        end
      end
    end
  end
end
