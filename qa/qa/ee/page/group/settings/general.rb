# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Settings
          module General
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                prepend ::QA::Page::Component::Dropdown
                prepend ::QA::Page::Settings::Common

                view 'ee/app/views/groups/_custom_project_templates_setting.html.haml' do
                  element :custom_project_templates_container
                  element :save_changes_button
                end

                view 'ee/app/assets/javascripts/pages/groups/edit/index.js' do
                  element :ip_restriction_field
                end

                view 'ee/app/views/groups/_member_lock_setting.html.haml' do
                  element :membership_lock_checkbox
                end

                view 'ee/app/views/groups/settings/_prevent_forking.html.haml' do
                  element :prevent_forking_outside_group_checkbox
                end

                view 'ee/app/views/shared/_repository_size_limit_setting.html.haml' do
                  element :repository_size_limit_field
                end

                view 'ee/app/views/groups/_templates_setting.html.haml' do
                  element :file_template_repositories_container
                  element :save_changes_button
                end

                view 'ee/app/views/groups/_user_caps_setting.html.haml' do
                  element :user_cap_limit_field
                end
              end
            end

            def current_custom_project_template
              expand_content(:custom_project_templates_container)

              within_element(:custom_project_templates_container) do
                current_selection
              end
            end

            def choose_custom_project_template(path)
              expand_content(:custom_project_templates_container)

              within_element(:custom_project_templates_container) do
                clear_current_selection_if_present
                expand_select_list
                search_and_select(path)
                click_element(:save_changes_button)
              end
            end

            def set_ip_address_restriction(ip_address)
              QA::Runtime::Logger.debug(%Q[Setting ip address restriction to: #{ip_address}])
              expand_content(:permission_lfs_2fa_content)

              # GitLab UI Token Selector (https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-token-selector--default)
              # `data-qa-*` can only be added to the wrapper so custom selector used to find token close buttons and text input
              find_element(:ip_restriction_field).all('[data-testid="close-icon"]', minimum: 0).each(&:click)

              ip_restriction_field_input = find_element(:ip_restriction_field).find('input[type="text"]')
              ip_restriction_field_input.set ip_address
              ip_restriction_field_input.send_keys(:enter)
              click_element(:save_permissions_changes_button)
            end

            def set_membership_lock_enabled
              expand_content(:permission_lfs_2fa_content)
              check_element(:membership_lock_checkbox, true)
              click_element(:save_permissions_changes_button)
            end

            def set_membership_lock_disabled
              expand_content(:permission_lfs_2fa_content)
              uncheck_element(:membership_lock_checkbox, true)
              click_element(:save_permissions_changes_button)
            end

            def set_prevent_forking_outside_group_enabled
              expand_content(:permission_lfs_2fa_content)
              check_element(:prevent_forking_outside_group_checkbox, true)
              click_element(:save_permissions_changes_button)
            end

            def set_prevent_forking_outside_group_disabled
              expand_content(:permission_lfs_2fa_content)
              uncheck_element(:prevent_forking_outside_group_checkbox, true)
              click_element(:save_permissions_changes_button)
            end

            def set_repository_size_limit(limit)
              find_element(:repository_size_limit_field).set limit
            end

            # Set group's user cap limit if feature flag is enabled
            #
            # @param limit [Integer, String] integer >=1, empty string removes the limit
            def set_saas_user_cap_limit(limit)
              # Need to wait for the input field to appear after the toggle is enabled
              Support::Retrier.retry_until(
                max_attempts: 10, retry_on_exception: true, reload_page: page, sleep_interval: 2
              ) do
                expand_content(:permission_lfs_2fa_content)
                find_element(:user_cap_limit_field, wait: 1).set limit
                click_element(:save_permissions_changes_button)
                wait_for_requests

                page.text.match?(/was successfully updated/i)
              end
            end

            def current_file_template_repository
              expand_content(:file_template_repositories_container)

              within_element(:file_template_repositories_container) do
                current_selection
              end
            end

            def choose_file_template_repository(path)
              expand_content(:file_template_repositories_container)

              within_element(:file_template_repositories_container) do
                clear_current_selection_if_present
                expand_select_list

                search_and_select(path)
                click_element(:save_changes_button)
              end
            end
          end
        end
      end
    end
  end
end
