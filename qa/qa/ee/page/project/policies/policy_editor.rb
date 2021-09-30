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

            def has_policy_type_form_select?
              has_element?(:policy_type_form_select)
            end
          end
        end
      end
    end
  end
end
