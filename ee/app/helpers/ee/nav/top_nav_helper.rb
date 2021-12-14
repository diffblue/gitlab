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
            title: _('Environments'),
            icon: 'environment',
            data: { qa_selector: 'environment_link' },
            href: operations_environments_path
          )
        end

        if dashboard_nav_link?(:operations)
          builder.add_primary_menu_item(
            id: 'operations',
            title: _('Operations'),
            icon: 'cloud-gear',
            data: { qa_selector: 'operations_link' },
            href: operations_path
          )
        end

        if dashboard_nav_link?(:security)
          builder.add_primary_menu_item(
            id: 'security',
            title: _('Security'),
            icon: 'shield',
            data: { qa_selector: 'security_link' },
            href: security_dashboard_path
          )
        end

        if ::Gitlab::Geo.secondary? && ::Gitlab::Geo.primary_node_configured?
          builder.add_secondary_menu_item(
            id: 'geo',
            title: _('Go to primary site'),
            icon: 'location-dot',
            href: ::Gitlab::Geo.primary_node.url
          )
        end
      end

      override :projects_submenu_items
      def projects_submenu_items(builder:)
        super

        if License.feature_available?(:adjourned_deletion_for_projects_and_groups)
          builder.add_primary_menu_item(id: 'deleted', title: _('Deleted projects'), href: removed_dashboard_projects_path)
        end
      end
    end
  end
end
