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

          # Sync can be started by a scheduled background job in which case
          # the "Sync now" button will not be shown
          def click_sync_now_if_needed
            wait_for_requests

            return unless has_element?(:sync_now_button, wait: 2)

            click_element :sync_now_button
            click_element :sync_ldap_confirm_button
          end
        end
      end
    end
  end
end
