# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          module ConfigurationForm
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/assets/javascripts/security_configuration/sast/components/configuration_form.vue' do
                  element :submit_button
                end

                view 'ee/app/assets/javascripts/security_configuration/sast/components/analyzer_configuration.vue' do
                  element :entity_checkbox, "`${entity.name}_checkbox`" # rubocop:disable QA/ElementWithPattern
                end
              end
            end

            def click_expand_button
              expand_content(:analyzer_settings_content)
            end

            def click_submit_button
              click_element(:submit_button)
            end

            def fill_dynamic_field(field_name, content)
              fill_element("#{field_name}_field", content)
            end

            def unselect_dynamic_checkbox(checkbox_name)
              uncheck_element("#{checkbox_name}_checkbox", true)
            end
          end
        end
      end
    end
  end
end
