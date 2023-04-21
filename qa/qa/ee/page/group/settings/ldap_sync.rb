# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Settings
          class LDAPSync < ::QA::Page::Base
            include QA::Page::Component::Dropdown

            view 'ee/app/views/ldap_group_links/_form.html.haml' do
              element :add_sync_button
              element :ldap_group_field
              element :ldap_sync_group_radio
              element :ldap_sync_user_filter_radio
              element :ldap_user_filter_field
            end

            def set_ldap_group_sync_method
              check_element(:ldap_sync_group_radio, true)
            end

            def set_ldap_user_filter_sync_method
              check_element(:ldap_sync_user_filter_radio, true)
            end

            def set_group_cn(group_cn)
              within_element(:ldap_group_field) do
                expand_select_list
              end
              search_and_select(group_cn)
            end

            def set_user_filter(user_filter)
              fill_element(:ldap_user_filter_field, user_filter)
            end

            def click_add_sync_button
              click_element(:add_sync_button)
            end
          end
        end
      end
    end
  end
end
