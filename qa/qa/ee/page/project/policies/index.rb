# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Policies
          class Index < QA::Page::Base
            view 'ee/app/assets/javascripts/security_orchestration/components/policies/list_component.vue' do
              element 'policies-list'
            end

            view 'ee/app/assets/javascripts/security_orchestration/components/policies/list_header.vue' do
              element 'new-policy-button'
            end

            def has_policies_list?
              has_element?('policies-list')
            end

            def click_new_policy_button
              click_element('new-policy-button')
            end
          end
        end
      end
    end
  end
end
