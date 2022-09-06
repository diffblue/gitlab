# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module MergeRequestApprovals
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/assets/javascripts/approvals/components/mr_edit/rule_input.vue' do
                  element :approvals_number_field
                end
              end
            end

            def set_default_number_of_approvals_required(number)
              fill_element(:approvals_number_field, number)
            end
          end
        end
      end
    end
  end
end
