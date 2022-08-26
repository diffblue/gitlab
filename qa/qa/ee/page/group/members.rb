# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class Members < QA::Page::Base
          view 'ee/app/helpers/groups/ldap_sync_helper.rb' do
            element :sync_now_button
          end

          view 'ee/app/helpers/groups/ldap_sync_helper.rb' do
            element :sync_ldap_confirm_button
          end

          def click_sync_now
            click_element :sync_now_button
            click_element :sync_ldap_confirm_button
          end
        end
      end
    end
  end
end
