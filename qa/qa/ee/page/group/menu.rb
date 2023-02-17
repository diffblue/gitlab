# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Menu
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              prepend QA::Page::Group::SubMenus::Common
            end
          end

          def go_to_issue_boards
            hover_issues do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Boards')
              end
            end
          end

          def go_to_group_iterations
            hover_issues do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Iterations')
              end
            end
          end

          def go_to_saml_sso_group_settings
            hover_group_administration do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'SAML SSO')
              end
            end
          end

          def go_to_ldap_sync_settings
            hover_group_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'LDAP Synchronization')
              end
            end
          end

          def click_contribution_analytics_item
            hover_group_analytics do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Contribution')
              end
            end
          end

          def click_group_insights_link
            hover_group_analytics do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Insights')
              end
            end
          end

          def click_group_epics_link
            within_sidebar do
              click_element(:sidebar_menu_link, menu_item: 'Epics')
            end
          end

          def click_group_security_link
            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Security dashboard')
              end
            end
          end

          def click_group_vulnerability_link
            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Vulnerability report')
              end
            end
          end

          def go_to_audit_events
            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Audit events')
              end
            end
          end

          def click_compliance_report_link
            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Compliance report')
              end
            end
          end

          def click_group_wiki_link
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Wiki')
              click_element(:sidebar_menu_link, menu_item: 'Wiki')
            end
          end

          def go_to_billing
            hover_group_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Billing')
              end
            end
          end

          def go_to_usage_quotas
            hover_group_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Usage Quotas')
              end
            end
          end

          private

          def hover_security_and_compliance
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Security & Compliance')
              find_element(:sidebar_menu_link, menu_item: 'Security & Compliance').hover

              yield
            end
          end

          def hover_group_analytics
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Analytics')
              find_element(:sidebar_menu_link, menu_item: 'Analytics').hover

              yield
            end
          end

          def hover_group_administration
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Administration')
              find_element(:sidebar_menu_link, menu_item: 'Administration').hover

              yield
            end
          end
        end
      end
    end
  end
end
