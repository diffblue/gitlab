# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Monitor
          module OnCallSchedule
            class New < QA::Page::Base
              include QA::Page::Component::Dropdown

              view 'ee/app/assets/javascripts/oncall_schedules/components/oncall_schedules_wrapper.vue' do
                element :add_on_call_schedule_button
              end

              view 'ee/app/assets/javascripts/oncall_schedules/components/add_edit_schedule_form.vue' do
                element :schedule_name_field
                element :schedule_timezone_container
              end

              view 'ee/app/assets/javascripts/oncall_schedules/components/add_edit_schedule_modal.vue' do
                element :add_schedule_button
              end

              def open_add_schedule_modal
                click_element(:add_on_call_schedule_button)
              end

              def set_schedule_name(name: Faker::Lorem.word)
                fill_element(:schedule_name_field, name)
              end

              def select_timezone(timezone: 'Pacific Time (US & Canada)')
                within_element(:schedule_timezone_container) do
                  expand_select_list(css: '.btn.dropdown-toggle')
                  select_item(timezone, css: 'li.gl-dropdown-item')
                end
              end

              def save_new_schedule
                click_element(:add_schedule_button)
              end
            end
          end
        end
      end
    end
  end
end
