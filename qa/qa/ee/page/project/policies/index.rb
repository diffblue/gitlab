# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Policies
          class Index < QA::Page::Base
            view 'ee/app/assets/javascripts/security_orchestration/components/policies/policies_list.vue' do
              element :policies_list
            end

            view 'ee/app/assets/javascripts/security_orchestration/components/policies/policies_header.vue' do
              element :new_policy_button
            end

            def has_policies_list?
              has_element?(:policies_list)
            end

            def click_new_policy_button
              click_element(:new_policy_button)
            end
          end
        end
      end
    end
  end
end
