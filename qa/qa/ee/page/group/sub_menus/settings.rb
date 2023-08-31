# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module SubMenus
          module Settings
            extend QA::Page::PageConcern

            def go_to_saml_sso_group_settings
              open_settings_submenu('SAML SSO')
            end

            def go_to_ldap_sync_settings
              open_settings_submenu('LDAP Synchronization')
            end

            def go_to_billing
              open_settings_submenu('Billing')
            end

            def go_to_usage_quotas
              open_settings_submenu('Usage Quotas')
            end
          end
        end
      end
    end
  end
end
