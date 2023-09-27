# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Menu
          extend QA::Page::PageConcern

          include Sidebar::Settings
          include Sidebar::Monitoring

          def self.included(base)
            super

            base.class_eval do
              view 'ee/lib/ee/sidebars/admin/menus/admin_settings_menu.rb' do
                element 'admin-settings-advanced-search-link'
                element 'admin-settings-templates-link'
                element 'admin-security-and-compliance-link'
              end

              view 'ee/lib/sidebars/admin/menus/geo_menu.rb' do
                element 'admin-geo-menu-link'
              end

              view 'ee/lib/sidebars/admin/menus/subscription_menu.rb' do
                element 'admin-subscription-menu-link'
              end

              view 'ee/lib/ee/sidebars/admin/menus/monitoring_menu.rb' do
                element 'admin-monitoring-audit-logs-link'
              end
            end
          end

          def click_geo_menu_link
            click_element 'admin-geo-menu-link'
          end

          def click_subscription_menu_link
            click_element 'admin-subscription-menu-link'
          end
        end
      end
    end
  end
end
