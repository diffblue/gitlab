# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Settings
          class SamlSSO < ::QA::Page::Base
            view 'ee/app/views/groups/saml_providers/_form.html.haml' do
              element :identity_provider_sso_field
              element :certificate_fingerprint_field
              element :default_membership_role_dropdown
              element :enforced_sso_checkbox
              element :group_managed_accounts_checkbox
              element :save_changes_button
            end

            view 'ee/app/views/groups/saml_providers/_test_button.html.haml' do
              element :saml_settings_test_button
            end

            view 'ee/app/views/groups/saml_providers/_info.html.haml' do
              element :user_login_url_link
            end

            def set_id_provider_sso_url(url)
              fill_element :identity_provider_sso_field, url
            end

            def set_cert_fingerprint(fingerprint)
              fill_element :certificate_fingerprint_field, fingerprint
            end

            def set_default_membership_role(role)
              select_element(:default_membership_role_dropdown, role)
            end

            def has_enforced_sso_checkbox?
              has_checkbox = has_element?(:enforced_sso_checkbox, visible: false, wait: 5)
              QA::Runtime::Logger.debug "has_enforced_sso_checkbox?: #{has_checkbox}"
              has_checkbox
            end

            def enforce_sso_enabled?
              enabled = has_enforced_sso_checkbox? && find_element(:enforced_sso_checkbox, visible: false).checked?
              QA::Runtime::Logger.debug "enforce_sso_enabled?: #{enabled}"
              enabled
            end

            def enforce_sso
              check_element(:enforced_sso_checkbox, true) unless enforce_sso_enabled?
              Support::Waiter.wait_until(raise_on_failure: true) { enforce_sso_enabled? }
            end

            def disable_enforced_sso
              uncheck_element(:enforced_sso_checkbox, true) if enforce_sso_enabled?
              Support::Waiter.wait_until(raise_on_failure: true) { !enforce_sso_enabled? }
            end

            def has_group_managed_accounts_checkbox?
              has_element?(:group_managed_accounts_checkbox, wait: 5)
            end

            def group_managed_accounts_enabled?
              enforce_sso_enabled? && has_group_managed_accounts_checkbox? && find_element(:group_managed_accounts_checkbox).checked?
            end

            def enable_group_managed_accounts
              check_element(:group_managed_accounts_checkbox, true) unless group_managed_accounts_enabled?
              Support::Waiter.wait_until { group_managed_accounts_enabled? }
            end

            def disable_group_managed_accounts
              uncheck_element(:group_managed_accounts_checkbox, true) if group_managed_accounts_enabled?
              Support::Waiter.wait_until { !group_managed_accounts_enabled? }
            end

            def click_save_changes
              click_element :save_changes_button
            end

            def click_test_button
              click_element(:saml_settings_test_button)
            end

            def click_user_login_url_link
              click_element :user_login_url_link
            end

            def user_login_url_link_text
              find_element(:user_login_url_link).text
            end
          end
        end
      end
    end
  end
end
