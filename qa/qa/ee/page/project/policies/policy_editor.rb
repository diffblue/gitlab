# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Policies
          class PolicyEditor < QA::Page::Base
            view 'ee/app/assets/javascripts/threat_monitoring/components/policy_editor/policy_editor.vue' do
              element :policy_type_form_select
            end

            # Switch to just this when removing the :container_security_policy_selection feature flag
            view 'ee/app/assets/javascripts/threat_monitoring/components/policy_editor/policy_selection.vue' do
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
