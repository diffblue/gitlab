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
              if QA::Runtime::Env.super_sidebar_enabled?
                prepend SubMenus::SuperSidebar::Main
                prepend SubMenus::SuperSidebar::Secure
                prepend SubMenus::SuperSidebar::Plan
                prepend SubMenus::SuperSidebar::Analyze
                prepend SubMenus::SuperSidebar::Manage
                prepend SubMenus::SuperSidebar::Settings
              end
            end
          end

          def go_to_issue_boards
            return super if QA::Runtime::Env.super_sidebar_enabled?

            hover_issues do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Boards')
              end
            end
          end

          def go_to_group_iterations
            return super if QA::Runtime::Env.super_sidebar_enabled?

            hover_issues do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Iterations')
              end
            end
          end

          def go_to_saml_sso_group_settings
            return super if QA::Runtime::Env.super_sidebar_enabled?

            hover_group_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'SAML SSO')
              end
            end
          end

          def go_to_ldap_sync_settings
            return super if QA::Runtime::Env.super_sidebar_enabled?

            hover_group_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'LDAP Synchronization')
              end
            end
          end

          def click_contribution_analytics_item
            return go_to_contribution_analytics if QA::Runtime::Env.super_sidebar_enabled?

            hover_group_analytics do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Contribution')
              end
            end
          end

          def click_group_insights_link
            return go_to_insights if QA::Runtime::Env.super_sidebar_enabled?

            hover_group_analytics do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Insights')
              end
            end
          end

          def click_group_epics_link
            return go_to_epics if QA::Runtime::Env.super_sidebar_enabled?

            within_sidebar do
              click_element(:sidebar_menu_link, menu_item: 'Epics')
            end
          end

          def click_group_security_link
            return go_to_security_dashboard if QA::Runtime::Env.super_sidebar_enabled?

            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Security dashboard')
              end
            end
          end

          def click_group_vulnerability_link
            return go_to_vulnerability_report if QA::Runtime::Env.super_sidebar_enabled?

            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Vulnerability report')
              end
            end
          end

          def go_to_audit_events
            return super if QA::Runtime::Env.super_sidebar_enabled?

            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Audit events')
              end
            end
          end

          def click_compliance_report_link
            return go_to_compliance_report if QA::Runtime::Env.super_sidebar_enabled?

            hover_security_and_compliance do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Compliance report')
              end
            end
          end

          def click_group_wiki_link
            return go_to_wiki if QA::Runtime::Env.super_sidebar_enabled?

            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Wiki')
              click_element(:sidebar_menu_link, menu_item: 'Wiki')
            end
          end

          def go_to_billing
            return super if QA::Runtime::Env.super_sidebar_enabled?

            hover_group_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Billing')
              end
            end
          end

          def go_to_usage_quotas
            return super if QA::Runtime::Env.super_sidebar_enabled?

            hover_group_settings do
              within_submenu do
                click_element(:sidebar_menu_item_link, menu_item: 'Usage Quotas')
              end
            end
          end

          private

          def hover_security_and_compliance
            within_sidebar do
              scroll_to_element(:sidebar_menu_link, menu_item: 'Security and Compliance')
              find_element(:sidebar_menu_link, menu_item: 'Security and Compliance').hover

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
        end
      end
    end
  end
end
