# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Monitor
          module EscalationPolicies
            class New < QA::Page::Base
              include QA::Page::Component::Dropdown

              view 'ee/app/assets/javascripts/escalation_policies/components/add_edit_escalation_policy_form.vue' do
                element :escalation_policy_name_field
              end

              view 'ee/app/assets/javascripts/escalation_policies/components/escalation_rule.vue' do
                element :schedule_dropdown
              end

              def open_new_policy_modal
                click_button('Add an escalation policy')
                wait_for_requests
              end

              def set_policy_name(name: Faker::Lorem.word)
                fill_element(:escalation_policy_name_field, name)
              end

              def select_schedule(schedule_name)
                click_element(:schedule_dropdown)
                select_item(schedule_name, css: 'p.gl-dropdown-item-text-primary')
              end

              def save_new_policy
                click_button('Add escalation policy')
              end
            end
          end
        end
      end
    end
  end
end
