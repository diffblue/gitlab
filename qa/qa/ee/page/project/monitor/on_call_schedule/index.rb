# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Monitor
          module OnCallSchedule
            class Index < QA::Page::Base
              include QA::Page::Component::Dropdown
              include QA::Support::Dates

              # rubocop:disable Layout/LineLength
              view 'ee/app/assets/javascripts/oncall_schedules/components/rotations/components/add_edit_rotation_form.vue' do
                element 'rotation-name-field'
                element 'state-date-field'
              end
              # rubocop:enable Layout/LineLength

              def open_add_rotation_modal
                click_button('Add a rotation')
              end

              def set_rotation_name(name: Faker::Lorem.word)
                fill_element('rotation-name-field', name)
              end

              def select_participant(username: nil)
                expand_select_list(css: 'div.gl-token-selector')
                select_item(username, css: 'ul.dropdown-menu')
              end

              def set_start_date
                fill_element('state-date-field', current_date_yyyy_mm_dd)
                send_keys_to_element('state-date-field', :enter)
              end

              def save_new_rotation
                click_button 'Add rotation'
              end
            end
          end
        end
      end
    end
  end
end
