# frozen_string_literal: true

module QA
  module EE
    module Page
      module Registration
        module Welcome
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'ee/app/views/registrations/welcome/_button.html.haml' do
                element :get_started_button
              end

              view 'ee/app/views/registrations/welcome/_setup_for_company.html.haml' do
                element :setup_for_just_me_content
                element :setup_for_just_me_radio
              end

              view 'ee/app/views/registrations/welcome/_joining_project.html.haml' do
                element :create_a_new_project_radio
              end
            end
          end

          def choose_create_a_new_project_if_available
            click_element(:create_a_new_project_radio) if has_element?(:create_a_new_project_radio, wait: 1)
          end

          def choose_setup_for_just_me_if_available
            choose_element(:setup_for_just_me_radio, true) if has_element?(:setup_for_just_me_content, wait: 1)
          end
        end
      end
    end
  end
end
