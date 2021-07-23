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

              view 'app/views/layouts/nav/sidebar/_group_menus.html.haml' do
                element :group_issue_boards_link
                element :group_issues_item
                element :group_sidebar_submenu
                element :group_settings
              end

              view 'app/views/layouts/nav/sidebar/_wiki_link.html.haml' do
                element :wiki_link
              end

              view 'ee/app/views/groups/ee/_administration_nav.html.haml' do
                element :group_administration_link
                element :group_sidebar_submenu_content
                element :group_saml_sso_link
              end

              view 'ee/app/views/groups/ee/_settings_nav.html.haml' do
                element :ldap_synchronization_link
                element :billing_link
              end
              view 'ee/app/views/layouts/nav/ee/_epic_link.html.haml' do
                element :group_epics_link
              end

              view 'ee/app/views/layouts/nav/ee/_security_link.html.haml' do
                element :security_compliance_link
                element :group_secure_submenu
                element :security_dashboard_link
                element :vulnerability_report_link
                element :audit_events_settings_link
              end

              view 'ee/app/views/layouts/nav/_group_insights_link.html.haml' do
                element :group_insights_link
              end

              view 'ee/app/views/layouts/nav/sidebar/_group_iterations_link.html.haml' do
                element :group_iterations_link
              end

              view 'ee/app/views/groups/sidebar/_packages.html.haml' do
                element :group_packages_item
                element :group_packages_link
                element :group_packages_submenu
              end
            end
          end

          def go_to_audit_events_settings
            hover_element(:security_compliance_link) do
              within_submenu(:group_secure_submenu) do
                click_element(:audit_events_settings_link)
              end
            end
          end

          def go_to_issue_boards
            hover_element(:group_issues_item) do
              within_submenu(:group_issues_sidebar_submenu) do
                click_element(:group_issue_boards_link)
              end
            end
          end

          def go_to_group_iterations
            hover_element(:group_issues_item) do
              within_submenu(:group_issues_sidebar_submenu) do
                click_element(:group_iterations_link)
              end
            end
          end

          def go_to_saml_sso_group_settings
            hover_element(:group_administration_link) do
              within_submenu(:group_sidebar_submenu_content) do
                click_element(:group_saml_sso_link)
              end
            end
          end

          def go_to_ldap_sync_settings
            hover_element(:group_settings) do
              within_submenu(:group_sidebar_submenu) do
                click_element(:ldap_synchronization_link)
              end
            end
          end

          def click_group_insights_link
            hover_element(:analytics_link) do
              within_submenu(:analytics_sidebar_submenu) do
                click_element(:group_insights_link)
              end
            end
          end

          def click_group_general_settings_item
            hover_element(:group_settings) do
              within_submenu(:group_sidebar_submenu) do
                click_element(:general_settings_link)
              end
            end
          end

          def click_group_epics_link
            within_sidebar do
              click_element(:group_epics_link)
            end
          end

          def click_group_security_link
            hover_element(:security_compliance_link) do
              within_submenu(:group_secure_submenu) do
                click_element(:security_dashboard_link)
              end
            end
          end

          def click_group_vulnerability_link
            hover_element(:security_compliance_link) do
              within_submenu(:group_secure_submenu) do
                click_element(:vulnerability_report_link)
              end
            end
          end

          def go_to_group_packages
            hover_element(:group_packages_item) do
              within_submenu(:group_packages_submenu) do
                click_element(:group_packages_link)
              end
            end
          end

          def click_group_wiki_link
            within_sidebar do
              click_element(:wiki_link)
            end
          end

          def go_to_billing
            hover_element(:group_settings) do
              within_submenu(:group_sidebar_submenu) do
                click_element(:billing_link)
              end
            end
          end
        end
      end
    end
  end
end
