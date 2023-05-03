# frozen_string_literal: true

module EE
  module Sidebars
    module Admin
      module Menus
        module AdminSettingsMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            insert_item_after(:general_settings, advanced_search_menu_item)
            insert_item_after(:admin_reporting, templates_menu_item)
            insert_item_after(:admin_ci_cd, security_and_compliance_menu_item)

            true
          end

          private

          def advanced_search_menu_item
            unless ::License.feature_available?(:elastic_search)
              return ::Sidebars::NilMenuItem.new(item_id: :advanced_search)
            end

            ::Sidebars::MenuItem.new(
              title: _('Advanced Search'),
              link: advanced_search_admin_application_settings_path,
              active_routes: { path: 'admin/application_settings#advanced_search' },
              item_id: :advanced_search,
              container_html_options: { 'data-qa-selector': 'admin_settings_advanced_search_link' }
            )
          end

          def templates_menu_item
            unless ::License.feature_available?(:custom_file_templates)
              return ::Sidebars::NilMenuItem.new(item_id: :admin_templates)
            end

            ::Sidebars::MenuItem.new(
              title: _('Templates'),
              link: templates_admin_application_settings_path,
              active_routes: { path: 'admin/application_settings#templates' },
              item_id: :admin_templates,
              container_html_options: { 'data-qa-selector': 'admin_settings_templates_link' }
            )
          end

          def security_and_compliance_menu_item
            unless ::License.feature_available?(:license_scanning)
              return ::Sidebars::NilMenuItem.new(item_id: :admin_security_and_compliance)
            end

            ::Sidebars::MenuItem.new(
              title: _('Security and Compliance'),
              link: security_and_compliance_admin_application_settings_path,
              active_routes: { path: 'admin/application_settings#security_and_compliance' },
              item_id: :admin_security_and_compliance,
              container_html_options: { 'data-qa-selector': 'admin_security_and_compliance_link' }
            )
          end
        end
      end
    end
  end
end
