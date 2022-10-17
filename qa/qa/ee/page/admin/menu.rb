# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Menu
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
                element :admin_settings_templates_link
                element :admin_settings_advanced_search_link
              end

              view 'ee/app/views/layouts/nav/ee/admin/_geo_sidebar.html.haml' do
                element :admin_geo_menu_link
              end

              view 'ee/app/views/layouts/nav/sidebar/_licenses_link.html.haml' do
                element :admin_subscription_menu_link
              end

              view 'ee/app/views/layouts/nav/ee/admin/_new_monitoring_sidebar.html.haml' do
                element :admin_monitoring_audit_logs_link
              end
            end
          end

          def go_to_monitoring_audit_logs
            hover_element(:admin_monitoring_menu_link) do
              within_submenu(:admin_monitoring_submenu_content) do
                click_element :admin_monitoring_audit_logs_link
              end
            end
          end

          def click_geo_menu_link
            click_element :admin_geo_menu_link
          end

          def click_subscription_menu_link
            click_element :admin_subscription_menu_link
          end

          def go_to_template_settings
            hover_element(:admin_settings_menu_link) do
              within_submenu(:admin_settings_submenu_content) do
                click_element :admin_settings_templates_link
              end
            end
          end

          def go_to_advanced_search
            hover_element(:admin_settings_menu_link) do
              within_submenu(:admin_settings_submenu_content) do
                click_element :admin_settings_advanced_search_link
              end
            end
          end
        end
      end
    end
  end
end
