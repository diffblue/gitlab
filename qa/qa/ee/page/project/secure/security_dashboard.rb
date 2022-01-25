# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class SecurityDashboard < QA::Page::Base
            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_list.vue' do
              element :vulnerability
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_list.vue' do
              element :false_positive_vulnerability
            end

            def has_vulnerability?(description:)
              has_element?(:vulnerability, vulnerability_description: description)
            end

            def has_false_positive_vulnerability?
              has_element?(:false_positive_vulnerability)
            end

            def click_vulnerability(description:)
              return false unless has_vulnerability?(description: description)

              click_element(:vulnerability, vulnerability_description: description)
            end
          end
        end
      end
    end
  end
end
