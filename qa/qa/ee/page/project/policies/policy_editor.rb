# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Policies
          class PolicyEditor < QA::Page::Base
            view 'ee/app/assets/javascripts/security_orchestration/components/policy_editor/policy_selection.vue' do
              element :policy_selection_wizard
            end

            def has_policy_selection?(selector)
              has_element?(selector)
            end
          end
        end
      end
    end
  end
end
