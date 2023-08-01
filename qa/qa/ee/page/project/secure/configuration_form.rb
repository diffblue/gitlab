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
                  element 'submit-button'
                end
              end
            end

            def click_submit_button
              click_element('submit-button')
            end

            def fill_dynamic_field(field_name, content)
              fill_element("#{field_name}_field", content)
            end
          end
        end
      end
    end
  end
end
