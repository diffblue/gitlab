# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Menu
          extend QA::Page::PageConcern

          if QA::Runtime::Env.super_sidebar_enabled?
            prepend Sidebar::Settings
            prepend Sidebar::Monitoring
          end

          def self.prepended(base)
            super

            base.class_eval do
              view 'ee/lib/ee/sidebars/admin/menus/admin_settings_menu.rb' do
                element :admin_settings_advanced_search_link
                element :admin_settings_templates_link
                element :admin_security_and_compliance_link
              end

              view 'ee/lib/sidebars/admin/menus/geo_menu.rb' do
                element :admin_geo_menu_link
              end

              view 'ee/lib/sidebars/admin/menus/subscription_menu.rb' do
                element :admin_subscription_menu_link
              end

              view 'ee/lib/ee/sidebars/admin/menus/monitoring_menu.rb' do
                element :admin_monitoring_audit_logs_link
              end
            end
          end

          def go_to_monitoring_audit_events
            hover_element(:admin_monitoring_menu_link) do
              click_element :admin_monitoring_audit_logs_link
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
              click_element :admin_settings_templates_link
            end
          end

          def go_to_advanced_search
            hover_element(:admin_settings_menu_link) do
              click_element :admin_settings_advanced_search_link
            end
          end
        end
      end
    end
  end
end
