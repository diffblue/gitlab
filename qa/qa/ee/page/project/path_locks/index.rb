# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module PathLocks
          class Index < QA::Page::Base
            include QA::Page::Component::ConfirmModal

            view 'ee/app/views/projects/path_locks/_path_lock.html.haml' do
              element :locked_file_content
              element :locked_file_title_content
              element :unlock_button
            end

            def has_file_with_title?(file_title)
              has_element? :locked_file_title_content, text: file_title
            end

            def unlock_file(file_title)
              within_element :locked_file_content, text: file_title do
                click_element :unlock_button
              end
              click_confirmation_ok_button
            end
          end
        end
      end
    end
  end
end
