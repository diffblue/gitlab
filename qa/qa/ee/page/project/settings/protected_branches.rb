# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module ProtectedBranches
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/views/protected_branches/ee/_code_owner_approval_table.html.haml' do
                  element :code_owner_toggle_button
                end

                view 'app/assets/javascripts/protected_branches/protected_branch_create.js' do
                  element 'allowed-to-push-dropdown'
                  element 'allowed-to-merge-dropdown'
                end
              end
            end

            def require_code_owner_approval(branch)
              toggle = find_element(:code_owner_toggle_button, branch_name: branch).find_button('button')
              toggle.click unless toggle[:class].include?('is-checked')
            end

            private

            def select_allowed(action, allowed)
              super

              # Click the select element again to close the dropdown
              within_element("allowed-to-#{action}-dropdown") do
                click_element ".js-allowed-to-#{action}"
              end
            end
          end
        end
      end
    end
  end
end
