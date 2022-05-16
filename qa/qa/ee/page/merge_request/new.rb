# frozen_string_literal: true

module QA
  module EE
    module Page
      module MergeRequest
        module New
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              prepend ::QA::Page::Component::Select2

              view 'ee/app/assets/javascripts/approvals/components/app.vue' do
                element :add_approvers_button
              end

              view 'ee/app/assets/javascripts/approvals/components/rule_form.vue' do
                element :approvals_required_field
                element :member_select_field
                element :rule_name_field
              end

              def add_approval_rules(rules)
                # The Approval rules button/link is a gitlab-ui component that doesn't have a QA selector
                click_button('Approval rules')

                rules.each do |rule|
                  click_element :add_approvers_button

                  wait_for_animated_element :rule_name_field

                  fill_element :rule_name_field, rule[:name]
                  fill_element :approvals_required_field, rule[:approvals_required]

                  rule.key?(:users) && rule[:users].each do |user|
                    select_user_member(user.username)
                  end
                  rule.key?(:groups) && rule[:groups].each do |group|
                    select_group_member(group.full_path)
                  end

                  click_approvers_modal_ok_button
                end
              end

              # The Add/Update approvers modal is a gitlab-ui component built on
              # a bootstrap-vue component. It doesn't seem straightforward to
              # add a data attribute to the 'Ok' button without overriding it
              # So we break the rules and use a CSS selector instead of an element
              def click_approvers_modal_ok_button
                find("#mr-edit-approvals-create-modal footer button.btn-confirm").click
              end

              # Select2 is an external library, so we can't add our own selector
              def select_user_member(name)
                enter_member(name)
                find('.select2-results .user-username', text: "@#{name}").click
              end

              def select_group_member(path)
                enter_member(path)
                find('.select2-results .group-path', text: "#{path}").click
              end

              private

              def enter_member(name)
                retry_until do
                  within_element(:member_select_field) do
                    search_item(name)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
