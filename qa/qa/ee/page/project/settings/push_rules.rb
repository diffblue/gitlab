# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          class PushRules < QA::Page::Base
            view 'ee/app/views/shared/push_rules/_form.html.haml' do
              element :deny_delete_tag_checkbox
              element :restrict_author_checkbox
              element :prevent_secrets_checkbox
              element :commit_message_field
              element :deny_commit_message_field
              element :branch_name_field
              element :author_email_field
              element :file_name_field
              element :file_size_field
              element :submit_settings_button
            end

            view 'ee/app/views/shared/push_rules/_reject_unsigned_commits_setting.html.haml' do
              element :reject_unsigned_commits_checkbox
            end

            view 'ee/app/views/shared/push_rules/_commit_committer_check_setting.html.haml' do
              element :committer_restriction_checkbox
            end

            def check_reject_unsigned_commits
              check_element(:reject_unsigned_commits_checkbox, true)
            end

            def check_committer_restriction
              check_element(:committer_restriction_checkbox, true)
            end

            def check_deny_delete_tag
              check_element(:deny_delete_tag_checkbox, true)
            end

            def check_restrict_author
              check_element(:restrict_author_checkbox, true)
            end

            def check_prevent_secrets
              check_element(:prevent_secrets_checkbox, true)
            end

            def fill_commit_message_rule(message)
              fill_element :commit_message_field, message
            end

            def fill_deny_commit_message_rule(message)
              fill_element :deny_commit_message_field, message
            end

            def fill_branch_name(name)
              fill_element :branch_name_field, name
            end

            def fill_author_email(email)
              fill_element :author_email_field, email
            end

            def fill_file_name(file_name)
              fill_element :file_name_field, file_name
            end

            def fill_file_size(file_size)
              fill_element :file_size_field, file_size
            end

            def click_submit
              click_element :submit_settings_button
            end
          end
        end
      end
    end
  end
end
