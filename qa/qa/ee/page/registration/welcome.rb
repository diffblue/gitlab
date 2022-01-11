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
                element :setup_for_company_radio
              end
            end
          end

          # setup_for_company_radio is only shown in development environment and .com
          def choose_setup_for_company_if_available
            choose_element(:setup_for_company_radio) if QA::Runtime::Env.running_on_dev_or_dot_com?
          end
        end
      end
    end
  end
end
