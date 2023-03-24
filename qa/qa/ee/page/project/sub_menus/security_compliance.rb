# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module SecurityCompliance
            extend QA::Page::PageConcern

            def click_on_security_dashboard
              within_sidebar do
                click_element(:sidebar_menu_item_link, menu_item: 'Security dashboard')
              end
            end

            def go_to_dependency_list
              hover_security_compliance do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Dependency list')
                end
              end
            end

            def click_on_threat_monitoring
              hover_security_compliance do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Threat monitoring')
                end
              end
            end

            def go_to_policies
              hover_security_compliance do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Policies')
                end
              end
            end

            def go_to_vulnerability_report
              hover_security_compliance do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Vulnerability report')
                end
              end
            end

            def go_to_security_configuration
              hover_security_compliance do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Security configuration')
                end
              end
            end

            def hover_security_compliance
              within_sidebar do
                find_element(:sidebar_menu_link, menu_item: 'Security and Compliance').hover

                yield
              end
            end

            def go_to_audit_events
              hover_security_compliance do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Audit events')
                end
              end
            end
          end
        end
      end
    end
  end
end
